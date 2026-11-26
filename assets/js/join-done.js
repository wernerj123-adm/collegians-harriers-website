// After the Yoco card checkout: show whether the payment came through. The portal hears from Yoco
// directly, so this page only reads the signup's status (with the private token from the link).
(() => {
  const box = document.getElementById('done');
  if (!box) return;
  const params = new URLSearchParams(location.search);
  const ref = params.get('ref') || '', token = params.get('t') || '', result = params.get('result');
  const esc = value => String(value ?? '').replace(/[&<>'"]/g, ch => ({'&': '&amp;', '<': '&lt;', '>': '&gt;', "'": '&#39;', '"': '&quot;'}[ch]));
  const rand = cents => 'R' + (cents / 100).toLocaleString('en-ZA', {minimumFractionDigits: cents % 100 ? 2 : 0});
  const head = '<span class="section-kicker">REFERENCE ' + esc(ref) + '</span>';
  const other = cents => '<p>You can still pay ' + rand(cents) + ' by EFT or at the club bar, quoting <strong>' + esc(ref) + '</strong>. Questions: collegians.harriers@outlook.com</p>';
  if (!/^CH\d{2}-\d{4}$/.test(ref) || !token) { box.innerHTML = '<h2>We could not find that signup.</h2><p>Email collegians.harriers@outlook.com and we will help.</p>'; return; }
  let tries = 0;
  async function check() {
    tries += 1;
    try {
      const response = await fetch(box.dataset.api + '/public/status/' + encodeURIComponent(ref) + '?t=' + encodeURIComponent(token), {cache: 'no-store'});
      if (!response.ok) throw new Error('not found');
      const data = await response.json();
      if (data.status === 'paid') { box.innerHTML = head + '<h2>Paid. Welcome to Collegians.</h2><p>Your membership is confirmed. Keep this reference.</p>'; return; }
      if (data.status === 'cancelled') { box.innerHTML = head + '<h2>This signup was cancelled.</h2><p>Sign up again on the <a class="text-link" href="join.html">join page</a>.</p>'; return; }
      if (result === 'cancelled') { box.innerHTML = head + '<h2>You left the card payment.</h2><p>Your signup is saved but not paid.</p>' + other(data.total_cents); return; }
      if (result === 'failed') { box.innerHTML = head + '<h2>The card payment did not go through.</h2><p>Nothing was taken. Your signup is saved.</p>' + other(data.total_cents); return; }
      if (tries < 10) { box.innerHTML = head + '<h2>Confirming your payment…</h2><p>This usually takes a few seconds.</p>'; setTimeout(check, 3000); return; }
      box.innerHTML = head + '<h2>Your payment is still being confirmed.</h2><p>If Yoco showed the payment as successful, you do not need to do anything; the club will confirm it. Questions: collegians.harriers@outlook.com</p>';
    } catch (error) {
      box.innerHTML = '<h2>We could not check this signup.</h2><p>Email collegians.harriers@outlook.com with your reference ' + esc(ref) + '.</p>';
    }
  }
  check();
})();
