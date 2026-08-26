(() => {
  const gallery = document.querySelector('[data-gallery]');
  if (!gallery) return;

  const slides = [...gallery.querySelectorAll('[data-gallery-slide]')];
  const dots = [...gallery.querySelectorAll('[data-gallery-dot]')];
  const previous = gallery.querySelector('[data-gallery-prev]');
  const next = gallery.querySelector('[data-gallery-next]');
  const toggle = gallery.querySelector('[data-gallery-toggle]');
  const toggleIcon = toggle.querySelector('[aria-hidden="true"]');
  const toggleLabel = toggle.querySelector('.gallery-control-label');
  const status = gallery.querySelector('[data-gallery-status]');
  const reducedMotion = window.matchMedia('(prefers-reduced-motion: reduce)');
  const captions = slides.map((slide) => slide.querySelector('figcaption strong').textContent.trim());
  let current = 0;
  let playing = !reducedMotion.matches;
  let timer = null;
  let pointerStart = null;

  const renderToggle = () => {
    toggle.setAttribute('aria-label', playing ? 'Pause slideshow' : 'Play slideshow');
    toggleIcon.textContent = playing ? 'Ⅱ' : '▶';
    toggleLabel.textContent = playing ? 'Pause' : 'Play';
  };

  const show = (index, announce = true) => {
    current = (index + slides.length) % slides.length;
    slides.forEach((slide, slideIndex) => {
      const active = slideIndex === current;
      slide.classList.toggle('is-active', active);
      slide.setAttribute('aria-hidden', String(!active));
    });
    dots.forEach((dot, dotIndex) => {
      const active = dotIndex === current;
      dot.classList.toggle('is-active', active);
      dot.setAttribute('aria-current', String(active));
    });
    if (announce) status.textContent = `Slide ${current + 1} of ${slides.length}: ${captions[current]}`;
  };

  const stopTimer = () => {
    window.clearInterval(timer);
    timer = null;
  };

  const startTimer = () => {
    stopTimer();
    if (playing && !document.hidden) timer = window.setInterval(() => show(current + 1, false), 6500);
  };

  const move = (step) => {
    show(current + step);
    startTimer();
  };

  previous.addEventListener('click', () => move(-1));
  next.addEventListener('click', () => move(1));
  dots.forEach((dot, index) => dot.addEventListener('click', () => {
    show(index);
    startTimer();
  }));

  toggle.addEventListener('click', () => {
    playing = !playing;
    renderToggle();
    startTimer();
  });

  gallery.addEventListener('pointerenter', stopTimer);
  gallery.addEventListener('pointerleave', startTimer);
  gallery.addEventListener('focusin', stopTimer);
  gallery.addEventListener('focusout', (event) => {
    if (!gallery.contains(event.relatedTarget)) startTimer();
  });
  gallery.addEventListener('pointerdown', (event) => {
    pointerStart = event.clientX;
  });
  gallery.addEventListener('pointerup', (event) => {
    if (pointerStart === null) return;
    const distance = event.clientX - pointerStart;
    pointerStart = null;
    if (Math.abs(distance) > 55) move(distance > 0 ? -1 : 1);
  });
  gallery.addEventListener('pointercancel', () => {
    pointerStart = null;
  });

  document.addEventListener('visibilitychange', () => {
    if (document.hidden) stopTimer(); else startTimer();
  });
  reducedMotion.addEventListener('change', (event) => {
    playing = !event.matches;
    renderToggle();
    startTimer();
  });

  renderToggle();
  show(0, false);
  startTimer();
})();
