const menuButton=document.querySelector('.menu-btn');const nav=document.querySelector('.nav-links');if(menuButton&&nav){menuButton.addEventListener('click',()=>{const open=nav.classList.toggle('open');menuButton.setAttribute('aria-expanded',String(open));menuButton.textContent=open?'×':'☰';});nav.querySelectorAll('a').forEach(link=>link.addEventListener('click',()=>{nav.classList.remove('open');menuButton.setAttribute('aria-expanded','false');menuButton.textContent='☰';}));}

// Release bar: staging and local previews only, never the live site.
//
// The button opens the pull request on GitHub rather than merging anything
// here. Merging from this page would mean putting a token into a file that
// anyone can read, so the merge stays on GitHub where it is the signed-in
// account that decides. Styles are inline because site.css is cache-busted
// per page and this must not force 21 pages to be re-versioned.
(() => {
  const host = location.hostname;
  const allowed = host.startsWith('staging.') || host === 'localhost' || host === '127.0.0.1';
  if (!allowed) return;

  const repo = 'wernerj123-adm/collegians-harriers-website';
  const compare = `https://github.com/${repo}/compare/main...develop?expand=1`;

  const bar = document.createElement('div');
  bar.setAttribute('role', 'complementary');
  bar.setAttribute('aria-label', 'Staging release');
  bar.style.cssText = 'position:fixed;right:16px;bottom:16px;z-index:9999;max-width:min(340px,calc(100vw - 32px));' +
    'background:#1b1b1b;color:#fff;border-radius:14px;padding:14px 16px;box-shadow:0 10px 30px rgba(0,0,0,.35);' +
    'font:14px/1.45 system-ui,-apple-system,"Segoe UI",sans-serif';
  bar.innerHTML =
    '<div style="display:flex;gap:10px;align-items:start;justify-content:space-between">' +
      '<strong style="font-size:.7rem;letter-spacing:.14em;text-transform:uppercase;color:#f3b3b6">Staging preview</strong>' +
      '<button type="button" aria-label="Hide this notice" style="background:none;border:0;color:#999;font-size:18px;' +
      'line-height:1;cursor:pointer;padding:0 2px">&times;</button>' +
    '</div>' +
    '<p data-state style="margin:8px 0 12px;color:#ddd">This is not the public site.</p>' +
    `<a href="${compare}" target="_blank" rel="noopener noreferrer" style="display:inline-block;background:#d71920;` +
    'color:#fff;font-weight:800;text-decoration:none;border-radius:999px;padding:9px 16px">Review and release to live &rarr;</a>';

  const state = bar.querySelector('[data-state]');
  bar.querySelector('button').addEventListener('click', () => {
    bar.remove();
    try { sessionStorage.setItem('release-bar-hidden', '1'); } catch {}
  });

  try { if (sessionStorage.getItem('release-bar-hidden')) return; } catch {}
  document.body.appendChild(bar);

  // How far ahead of live staging is. Best effort: the public API is rate
  // limited per address, so a failure leaves the button working and silent.
  fetch(`https://api.github.com/repos/${repo}/compare/main...develop`, {cache: 'no-store'})
    .then(response => response.ok ? response.json() : Promise.reject(new Error(String(response.status))))
    .then(body => {
      const ahead = body.ahead_by;
      state.textContent = ahead
        ? `${ahead} commit${ahead === 1 ? '' : 's'} here ${ahead === 1 ? 'is' : 'are'} not on the live site yet.`
        : 'The live site already matches this preview.';
    })
    .catch(() => {});
})();
