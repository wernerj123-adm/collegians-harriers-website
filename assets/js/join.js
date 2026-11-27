// 2027 membership signup: talks to the club portal, which works out the fees, keeps the signup
// and starts the Yoco card checkout. Nothing here decides an amount; it only shows what the portal says.
(() => {
  const form = document.getElementById('join-form');
  if (!form) return;
  const API = form.dataset.api;
  const YEAR = Number(form.dataset.year);
  const people = document.getElementById('people');
  const template = document.getElementById('person-template');
  const quoteBox = document.getElementById('quote');
  const errorBox = document.getElementById('join-error');
  const MAX = 8;
  let options = null, quoteTimer = null, quoteVersion = 0, sending = false;

  const esc = value => String(value ?? '').replace(/[&<>'"]/g, ch => ({'&': '&amp;', '<': '&lt;', '>': '&gt;', "'": '&#39;', '"': '&quot;'}[ch]));
  const rand = cents => 'R' + (cents / 100).toLocaleString('en-ZA', {minimumFractionDigits: cents % 100 ? 2 : 0});
  const show = (id, visible) => { document.getElementById(id).hidden = !visible; };

  async function api(path, body) {
    const response = await fetch(API + path, body ? {method: 'POST', headers: {'Content-Type': 'application/json'}, body: JSON.stringify(body)} : {});
    let data = {};
    try { data = await response.json(); } catch (e) { /* not JSON */ }
    if (!response.ok) throw new Error(data.message || data.error || 'Something went wrong. Please try again.');
    return data;
  }

  function age(dob) {
    if (!dob) return null;
    const born = new Date(dob + 'T00:00:00'), today = new Date();
    let years = today.getFullYear() - born.getFullYear();
    if (today < new Date(today.getFullYear(), born.getMonth(), born.getDate())) years -= 1;
    return years;
  }

  // Age on 31 December of the membership year decides the category (the portal checks the same rule).
  function ageAtYearEnd(dob) {
    if (!dob) return null;
    const born = new Date(dob + 'T00:00:00');
    return YEAR - born.getFullYear();
  }

  // A 13-digit SA ID number starts with the date of birth (YYMMDD): fill the birth date when it is empty.
  function dobFromId(block) {
    const id = block.querySelector('[data-f=id_number]').value.replace(/\s/g, '');
    const field = block.querySelector('[data-f=date_of_birth]');
    if (field.value || !/^\d{13}$/.test(id)) return;
    const yy = Number(id.slice(0, 2)), mm = id.slice(2, 4), dd = id.slice(4, 6);
    const year = (yy > new Date().getFullYear() % 100 ? 1900 : 2000) + yy;
    const iso = year + '-' + mm + '-' + dd;
    if (!Number.isNaN(new Date(iso + 'T00:00:00').getTime())) field.value = iso;
  }

  function checkCategory(block) {
    const select = block.querySelector('[data-f=category]');
    const note = block.querySelector('[data-category-note]');
    const category = options.categories.find(c => c.name === select.value);
    const years = ageAtYearEnd(block.querySelector('[data-f=date_of_birth]').value);
    let message = '';
    if (category && years !== null && category.min_age != null && (years < category.min_age || years > category.max_age)) {
      const fits = options.categories.filter(c => c.min_age != null && c.name !== 'Student' && years >= c.min_age && years <= c.max_age).map(c => c.name);
      message = category.name + ' is not available: this member will be ' + years + ' on 31 December ' + YEAR + '.'
        + (fits.length ? ' Choose ' + fits.join(' or ') + '.' : '');
    }
    select.setCustomValidity(message);
    note.textContent = message;
    note.hidden = !message;
    return !message;
  }

  function refresh(block) {
    dobFromId(block);
    checkCategory(block);
    const kind = (block.querySelector('[data-f=member_kind]:checked') || {}).value;
    const years = age(block.querySelector('[data-f=date_of_birth]').value);
    block.querySelector('[data-show=renewing]').hidden = kind !== 'renewing';
    block.querySelector('[data-show=joining]').hidden = !(kind === 'new' || kind === 'returning');
    block.querySelector('[data-show=minor]').hidden = !(years !== null && years < 18);
    const minor = years !== null && years < 18;
    const section = block.querySelector('[data-f=other_section]').checked;
    block.querySelector('[data-show=section]').hidden = !section;
    block.querySelector('[data-f=other_section_name]').required = section;
    updateRoutes();
    block.querySelector('[data-show=adult]').hidden = minor;
    for (const key of ['emergency_name', 'emergency_phone', 'email', 'phone']) block.querySelector('[data-f=' + key + ']').required = !minor;
    for (const key of ['guardian_name', 'guardian_phone', 'guardian_email']) block.querySelector('[data-f=' + key + ']').required = minor;
    block.querySelectorAll('[data-own-contact]').forEach(star => { star.textContent = minor ? '(if they have one)' : '*'; });
    const chosen = options.categories.find(c => c.name === block.querySelector('[data-f=category]').value);
    const tags = chosen ? chosen.tags_cents : null;
    block.querySelector('[data-show=tags]').hidden = !tags;
    block.querySelector('[data-tags-price]').textContent = tags ? '(R' + (tags / 100).toFixed(tags % 100 ? 2 : 0) + ')' : '';
    const kit = block.querySelector('[data-f=kit_choice]').value;
    block.querySelector('[data-f=kit_size]').disabled = !kit;
  }

  // A subsection claim waits for the committee, so it cannot be paid online straight away.
  function updateRoutes() {
    const claim = [...people.querySelectorAll('[data-f=other_section]')].some(box => box.checked);
    const card = document.querySelector('#route-card-wrap input');
    if (!options || !options.card_payments) return;
    card.disabled = claim;
    document.getElementById('route-card-wrap').classList.toggle('join-off', claim);
    if (claim && card.checked) card.checked = false;
  }

  function addPerson() {
    if (people.children.length >= MAX) return;
    const block = template.content.firstElementChild.cloneNode(true);
    const n = people.children.length + 1;
    block.querySelectorAll('[data-f=member_kind]').forEach(input => { input.name = 'member_kind_' + Date.now() + '_' + n; });
    block.querySelector('[data-f=category]').innerHTML = '<option value="">Choose</option>' + options.categories.map(c =>
      '<option value="' + esc(c.name) + '">' + esc(c.name) + '</option>').join('');
    block.querySelector('[data-f=kit_size]').innerHTML = '<option value="">Size</option>' + options.kit_sizes.map(s => '<option>' + esc(s) + '</option>').join('');
    if (n > 1) {
      const first = people.firstElementChild;
      for (const key of ['last_name', 'emergency_name', 'emergency_phone', 'guardian_name', 'guardian_phone', 'guardian_email']) block.querySelector('[data-f=' + key + ']').value = first.querySelector('[data-f=' + key + ']').value;
    }
    people.appendChild(block);
    renumber(); refresh(block);
  }

  function renumber() {
    [...people.children].forEach((block, i) => {
      block.querySelector('[data-n]').textContent = i + 1;
      block.querySelector('[data-remove]').hidden = people.children.length === 1;
    });
    document.getElementById('add-person').hidden = people.children.length >= MAX;
  }

  function readPerson(block) {
    const value = key => block.querySelector('[data-f=' + key + ']');
    const person = {member_kind: (block.querySelector('[data-f=member_kind]:checked') || {}).value || ''};
    for (const key of ['first_name', 'last_name', 'date_of_birth', 'gender', 'id_number', 'category', 'email', 'phone', 'emergency_name',
      'emergency_phone', 'previous_asa_number', 'previous_club', 'kit_choice', 'kit_size', 'guardian_name', 'guardian_phone', 'guardian_email', 'other_section_name']) {
      const field = value(key);
      if (field.closest('[hidden]')) continue;
      if (field.value.trim()) person[key] = field.value.trim();
    }
    person.other_section = value('other_section').checked;
    person.needs_licence = value('needs_licence').checked;
    person.card_lost = !value('card_lost').closest('[hidden]') && value('card_lost').checked;
    person.age_tags = !value('age_tags').closest('[hidden]') && value('age_tags').checked;
    return person;
  }

  function body() {
    return {year: YEAR, people: [...people.children].map(readPerson), coupon_code: form.elements.coupon_code.value.trim() || undefined};
  }

  function ready(person) {
    const contact = (person.emergency_name && person.emergency_phone) || (person.guardian_name && person.guardian_phone);
    return person.first_name && person.last_name && person.date_of_birth && person.gender && person.category && person.member_kind && contact;
  }

  function scheduleQuote() {
    clearTimeout(quoteTimer);
    quoteTimer = setTimeout(quote, 500);
  }

  async function quote() {
    const data = body();
    if (![...people.children].every(checkCategory)) { quoteBox.innerHTML = '<p class="join-error">Fix the category above to see the amount.</p>'; return; }
    if (!data.people.every(ready)) { quoteBox.innerHTML = '<p class="join-small">Fill in the members above to see the amount.</p>'; return; }
    const current = ++quoteVersion;
    try {
      const result = await api('/public/quote', data);
      if (current !== quoteVersion) return;
      quoteBox.innerHTML = result.people.map(p => '<div class="join-quote-person"><h3>' + esc(p.name) + '</h3><table class="join-quote">'
        + p.lines.map(l => '<tr><td>' + esc(l.label) + '</td><td>' + rand(l.amount_cents) + '</td></tr>').join('')
        + '</table></div>').join('') + '<p class="join-total">Total <strong>' + rand(result.total_cents) + '</strong></p>';
    } catch (error) {
      if (current === quoteVersion) quoteBox.innerHTML = '<p class="join-error">' + esc(error.message) + '</p>';
    }
  }

  function eftPanel(result) {
    const lines = options.eft_details.length
      ? '<ul class="join-bank">' + options.eft_details.map(l => '<li>' + esc(l) + '</li>').join('') + '</ul>'
      : '<p>The club will email the bank details to you.</p>';
    return lines + '<p>Use <strong>' + esc(result.reference) + '</strong> as the payment reference. Your membership starts once the club sees the payment.</p>';
  }

  function payCardButton() {
    return '<p><button type="button" class="btn" data-pay-card>Pay by card now</button> <span class="join-small">on Yoco\'s secure card page</span></p><p class="join-error" data-pay-error hidden></p>';
  }

  async function payByCard(result, button) {
    const error = button.closest('#join-result, #done').querySelector('[data-pay-error]');
    button.disabled = true; button.textContent = 'Opening Yoco…'; error.hidden = true;
    try {
      const response = await fetch(API + '/public/pay-card/' + encodeURIComponent(result.reference), {method: 'POST',
        headers: {'Content-Type': 'application/json'}, body: JSON.stringify({t: result.status_token || ''})});
      const data = await response.json().catch(() => ({}));
      if (!response.ok || !data.redirect_url) throw new Error(data.message || data.error || 'The card payment could not start. Try again, or pay by EFT.');
      location.href = data.redirect_url;
    } catch (e) {
      error.textContent = e.message; error.hidden = false; button.disabled = false; button.textContent = 'Pay by card now';
    }
  }

  function showResult(result, route) {
    const box = document.getElementById('join-result');
    let html = '<span class="section-kicker">REFERENCE ' + esc(result.reference) + '</span><h2>';
    if (result.committee_check) html += 'Thank you. The committee will confirm your subsection membership.</h2><p>Please wait before paying: the club will contact you with the amount due (' + rand(result.total_cents) + ' if confirmed). Then pay by ' + (route === 'bar' ? 'card or cash at the club bar' : 'EFT') + ', quoting <strong>' + esc(result.reference) + '</strong>.</p>' + (route === 'eft' ? eftPanel(result) : '');
    else if (result.status === 'paid') html += 'You are signed up.</h2><p>Nothing was due, so your membership is confirmed. Welcome to Collegians.</p>';
    else if (route === 'eft') html += 'Thank you. Now pay ' + rand(result.total_cents) + ' by EFT.</h2>' + eftPanel(result);
    else if (route === 'bar') html += 'Thank you. Pay ' + rand(result.total_cents) + ' at the club bar.</h2><p>Pay by card or cash at the Collegians Club bar and quote <strong>' + esc(result.reference) + '</strong>. Your membership starts once you have paid.</p>';
    else html += 'Your signup is saved.</h2><p>' + esc(result.card_error || 'The card payment could not start.') + ' You can pay ' + rand(result.total_cents) + ' by EFT instead.</p>' + eftPanel(result);
    // EFT or bar chosen, or the card did not start: they can still pay by card now (when card payments are on).
    if (!result.committee_check && result.status !== 'paid' && options.card_payments) html += payCardButton();
    html += '<p class="join-small">Keep this reference. Questions: collegians.harriers@outlook.com</p>';
    box.innerHTML = html;
    const pay = box.querySelector('[data-pay-card]');
    if (pay) pay.addEventListener('click', () => payByCard(result, pay));
    form.hidden = true; box.hidden = false;
    box.scrollIntoView({behavior: 'smooth', block: 'start'});
  }

  form.addEventListener('input', event => {
    const block = event.target.closest('.join-person');
    if (block) refresh(block);
    scheduleQuote();
  });
  form.addEventListener('change', event => { const block = event.target.closest('.join-person'); if (block) refresh(block); });
  people.addEventListener('click', event => {
    if (!event.target.matches('[data-remove]')) return;
    event.target.closest('.join-person').remove(); renumber(); scheduleQuote();
  });
  document.getElementById('add-person').addEventListener('click', () => { addPerson(); scheduleQuote(); });

  form.addEventListener('submit', async event => {
    event.preventDefault();
    if (sending) return;
    errorBox.hidden = true;
    const route = (form.querySelector('[name=payment_route]:checked') || {}).value;
    const problem = !form.checkValidity() ? 'Please fill in every field marked *.' : !route ? 'Choose how you will pay.' : null;
    if (problem) { form.reportValidity(); errorBox.textContent = problem; errorBox.hidden = false; return; }
    sending = true;
    const button = form.querySelector('.join-submit');
    button.disabled = true; button.textContent = 'Sending…';
    try {
      const data = Object.assign(body(), {payment_route: route, contact_email: form.elements.contact_email.value.trim(),
        contact_phone: form.elements.contact_phone.value.trim() || undefined, consent: form.elements.consent.checked, website: form.elements.website.value});
      const result = await api('/public/apply', data);
      if (result.redirect_url && result.redirect_url.startsWith('https://')) { window.location.assign(result.redirect_url); return; }
      showResult(result, route);
    } catch (error) {
      errorBox.textContent = error.message; errorBox.hidden = false;
    } finally {
      sending = false; button.disabled = false; button.textContent = 'Sign up';
    }
  });

  (async () => {
    try {
      options = await api('/public/options?year=' + YEAR);
    } catch (error) {
      document.getElementById('join-loading').textContent = 'The signup form could not load. Please try again later, or email collegians.harriers@outlook.com.';
      return;
    }
    show('join-loading', false);
    if (!options.open) { show('join-closed', true); return; }
    if (!options.card_payments) {
      document.getElementById('route-card-wrap').hidden = true;
      document.querySelector('#route-card-wrap input').disabled = true;
    }
    addPerson();
    form.hidden = false;
  })();
})();
