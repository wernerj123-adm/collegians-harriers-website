(() => {
  const library = document.querySelector('[data-photo-library]');
  if (!library) return;

  const source = library.dataset.source;
  const featuredList = library.querySelector('[data-photo-featured]');
  const archiveList = library.querySelector('[data-photo-list]');
  const status = library.querySelector('[data-photo-status]');
  const total = library.querySelector('[data-photo-total]');
  const search = library.querySelector('[data-photo-search]');
  const year = library.querySelector('[data-photo-year]');
  const activity = library.querySelector('[data-photo-activity]');
  let photos = [];

  const formatDate = (photo) => {
    if (photo.dateLabel) return photo.dateLabel;
    const parsed = new Date(`${photo.date}T12:00:00`);
    return Number.isNaN(parsed.getTime())
      ? photo.date
      : new Intl.DateTimeFormat('en-ZA', { day: 'numeric', month: 'long', year: 'numeric' }).format(parsed);
  };

  const makeCard = (photo, featured = false) => {
    const card = document.createElement('article');
    card.className = featured ? 'photo-card photo-card-featured' : 'photo-card';
    const link = document.createElement('a');
    link.href = photo.image;
    link.target = '_blank';
    link.rel = 'noopener noreferrer';
    link.setAttribute('aria-label', `Open full-size photo: ${photo.title}`);
    const image = document.createElement('img');
    image.src = photo.image;
    image.alt = photo.alt;
    image.loading = featured ? 'eager' : 'lazy';
    const copy = document.createElement('div');
    copy.className = 'photo-card-copy';
    const meta = document.createElement('span');
    meta.textContent = `${formatDate(photo)} · ${photo.activity}`;
    const heading = document.createElement('h3');
    heading.textContent = photo.title;
    const caption = document.createElement('p');
    caption.textContent = photo.caption;
    copy.append(meta, heading, caption);
    link.append(image, copy);
    card.append(link);
    return card;
  };

  const renderFeatured = () => {
    const latestWeek = photos.length ? (photos[0].week || photos[0].date) : null;
    const latest = photos.filter((photo) => (photo.week || photo.date) === latestWeek);
    featuredList.replaceChildren(...latest.map((photo) => makeCard(photo, true)));
  };

  const renderArchive = () => {
    const query = search.value.trim().toLowerCase();
    const selectedYear = year.value;
    const selectedActivity = activity.value;
    const visible = photos.filter((photo) => {
      const haystack = `${photo.title} ${photo.caption} ${photo.activity} ${photo.year}`.toLowerCase();
      return (!query || haystack.includes(query))
        && (selectedYear === 'all' || String(photo.year) === selectedYear)
        && (selectedActivity === 'all' || photo.activity === selectedActivity);
    });
    status.textContent = `Showing ${visible.length} of ${photos.length} photo${photos.length === 1 ? '' : 's'}`;
    archiveList.replaceChildren();
    if (!visible.length) {
      const empty = document.createElement('p');
      empty.className = 'photo-empty';
      empty.textContent = 'No photos match those filters.';
      archiveList.append(empty);
      return;
    }
    archiveList.append(...visible.map((photo) => makeCard(photo)));
  };

  fetch(source, { cache: 'no-store' })
    .then((response) => {
      if (!response.ok) throw new Error(`Photo register returned ${response.status}`);
      return response.json();
    })
    .then((data) => {
      photos = Array.isArray(data.photos)
        ? data.photos
          .filter((photo) => photo && photo.title && photo.date && photo.year && photo.activity && photo.image && photo.alt && photo.caption)
          .sort((a, b) => b.date.localeCompare(a.date) || a.title.localeCompare(b.title))
        : [];
      total.textContent = photos.length;
      [...new Set(photos.map((photo) => photo.year))].sort((a, b) => b - a)
        .forEach((value) => year.add(new Option(String(value), String(value))));
      [...new Set(photos.map((photo) => photo.activity))].sort()
        .forEach((value) => activity.add(new Option(value, value)));
      search.addEventListener('input', renderArchive);
      year.addEventListener('change', renderArchive);
      activity.addEventListener('change', renderArchive);
      renderFeatured();
      renderArchive();
    })
    .catch(() => {
      total.textContent = '—';
      status.textContent = 'Photo library unavailable';
      const error = document.createElement('p');
      error.className = 'photo-empty';
      error.textContent = 'The photo library could not be loaded. Please try again later.';
      featuredList.replaceChildren();
      archiveList.replaceChildren(error);
    });
})();
