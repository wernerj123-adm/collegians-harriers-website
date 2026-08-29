(() => {
  const gallery = document.querySelector('[data-gallery]');
  if (!gallery) return;

  const controls = gallery.querySelector('.gallery-controls');
  const dotsContainer = gallery.querySelector('.gallery-dots');
  const previous = gallery.querySelector('[data-gallery-prev]');
  const next = gallery.querySelector('[data-gallery-next]');
  const toggle = gallery.querySelector('[data-gallery-toggle]');
  const toggleIcon = toggle.querySelector('[aria-hidden="true"]');
  const toggleLabel = toggle.querySelector('.gallery-control-label');
  const status = gallery.querySelector('[data-gallery-status]');
  const reducedMotion = window.matchMedia('(prefers-reduced-motion: reduce)');
  const source = gallery.dataset.gallerySource;
  let slides = [];
  let dots = [];
  let captions = [];
  let counter = null;
  let current = 0;
  let playing = !reducedMotion.matches;
  let timer = null;
  let pointerStart = null;

  const createSlide = (photo, index) => {
    const figure = document.createElement('figure');
    figure.className = 'gallery-slide';
    figure.dataset.gallerySlide = '';
    figure.setAttribute('aria-hidden', 'true');
    if (/collegians-team-photo/i.test(photo.image || '')) figure.classList.add('gallery-slide-team');

    const image = document.createElement('img');
    image.src = photo.image;
    image.alt = photo.alt || photo.title || photo.album || 'Collegians Harriers club activity';
    image.loading = index === 0 ? 'eager' : 'lazy';
    if (index === 0) image.fetchPriority = 'high';

    const caption = document.createElement('figcaption');
    const number = document.createElement('span');
    number.textContent = String(index + 1).padStart(2, '0');
    const title = document.createElement('strong');
    title.textContent = photo.title || photo.album || photo.activity || 'Collegians Harriers';
    caption.append(number, title);
    figure.append(image, caption);
    return figure;
  };

  const rebuildSlides = (photos) => {
    if (!Array.isArray(photos) || photos.length === 0) return;
    gallery.querySelectorAll('[data-gallery-slide]').forEach((slide) => slide.remove());
    photos.forEach((photo, index) => gallery.insertBefore(createSlide(photo, index), controls));

    dotsContainer.replaceChildren();
    if (photos.length <= 10) {
      photos.forEach((photo, index) => {
        const dot = document.createElement('button');
        dot.type = 'button';
        dot.className = 'gallery-dot';
        dot.dataset.galleryDot = String(index);
        dot.setAttribute('aria-label', `Show slide ${index + 1}: ${photo.title || photo.album || 'Club activity'}`);
        dot.setAttribute('aria-current', 'false');
        dotsContainer.append(dot);
      });
    } else {
      counter = document.createElement('span');
      counter.className = 'gallery-counter';
      counter.setAttribute('aria-hidden', 'true');
      dotsContainer.append(counter);
    }
  };

  const loadRegisteredPhotos = async () => {
    if (!source) return;
    try {
      const response = await fetch(source, { cache: 'no-store' });
      if (!response.ok) throw new Error(`Photo register returned ${response.status}`);
      const register = await response.json();
      rebuildSlides(register.photos);
    } catch (error) {
      console.warn('Home slideshow is using its built-in fallback photographs.', error);
    }
  };

  const refreshCollections = () => {
    slides = [...gallery.querySelectorAll('[data-gallery-slide]')];
    dots = [...gallery.querySelectorAll('[data-gallery-dot]')];
    captions = slides.map((slide) => slide.querySelector('figcaption strong').textContent.trim());
  };

  const renderToggle = () => {
    toggle.setAttribute('aria-label', playing ? 'Pause slideshow' : 'Play slideshow');
    toggleIcon.textContent = playing ? 'Ⅱ' : '▶';
    toggleLabel.textContent = playing ? 'Pause' : 'Play';
  };

  const show = (index, announce = true) => {
    if (!slides.length) return;
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
    if (counter) counter.textContent = `${current + 1} / ${slides.length}`;
    if (announce) status.textContent = `Slide ${current + 1} of ${slides.length}: ${captions[current]}`;
  };

  const stopTimer = () => {
    window.clearInterval(timer);
    timer = null;
  };

  const startTimer = () => {
    stopTimer();
    if (playing && !document.hidden && slides.length > 1) {
      timer = window.setInterval(() => show(current + 1, false), 6500);
    }
  };

  const move = (step) => {
    show(current + step);
    startTimer();
  };

  const initialise = async () => {
    await loadRegisteredPhotos();
    refreshCollections();
    if (!slides.length) return;

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
    status.textContent = `Slide 1 of ${slides.length}: ${captions[0]}`;
    startTimer();
  };

  initialise();
})();
