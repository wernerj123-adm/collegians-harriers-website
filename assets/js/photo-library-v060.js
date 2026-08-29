(() => {
  const library = document.querySelector('[data-photo-library]');
  if (!library) return;

  const source = library.dataset.source;
  const indexView = library.querySelector('[data-photo-index]');
  const albumView = library.querySelector('[data-photo-album]');
  const featuredList = library.querySelector('[data-photo-featured]');
  const archiveList = library.querySelector('[data-photo-list]');
  const status = library.querySelector('[data-photo-status]');
  const total = library.querySelector('[data-photo-total]');
  const search = library.querySelector('[data-photo-search]');
  const year = library.querySelector('[data-photo-year]');
  const activity = library.querySelector('[data-photo-activity]');
  let photos = [];
  let albums = [];

  const slugify = (value) => value.toLowerCase().replace(/[^a-z0-9]+/g, '-').replace(/^-|-$/g, '') || 'club-album';

  const formatDate = (record) => {
    if (record.dateLabel) return record.dateLabel;
    const parsed = new Date(`${record.date}T12:00:00`);
    return Number.isNaN(parsed.getTime())
      ? record.date
      : new Intl.DateTimeFormat('en-ZA', { day: 'numeric', month: 'long', year: 'numeric' }).format(parsed);
  };

  const makePhotoCard = (photo) => {
    const card = document.createElement('article');
    card.className = 'photo-card';
    const link = document.createElement('a');
    link.href = photo.image;
    link.target = '_blank';
    link.rel = 'noopener noreferrer';
    link.setAttribute('aria-label', `Open full-size photo: ${photo.title}`);
    const image = document.createElement('img');
    image.src = photo.image;
    image.alt = photo.alt;
    image.loading = 'lazy';
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

  const makeAlbumCard = (album, featured = false) => {
    const card = document.createElement('article');
    card.className = featured ? 'photo-card photo-album-card photo-card-featured' : 'photo-card photo-album-card';
    const link = document.createElement('a');
    link.href = `photos.html?album=${encodeURIComponent(album.slug)}`;
    link.setAttribute('aria-label', `Open photo album: ${album.title}`);
    const cover = document.createElement('div');
    cover.className = 'photo-album-cover';
    const image = document.createElement('img');
    image.src = album.photos[0].image;
    image.alt = album.photos[0].alt;
    image.loading = featured ? 'eager' : 'lazy';
    const count = document.createElement('strong');
    count.className = 'photo-count';
    count.textContent = `${album.photos.length} photo${album.photos.length === 1 ? '' : 's'}`;
    cover.append(image, count);
    const copy = document.createElement('div');
    copy.className = 'photo-card-copy';
    const meta = document.createElement('span');
    meta.textContent = `${formatDate(album)} · ${album.activity}`;
    const heading = document.createElement('h3');
    heading.textContent = album.title;
    const description = document.createElement('p');
    description.textContent = 'Open album →';
    copy.append(meta, heading, description);
    link.append(cover, copy);
    card.append(link);
    return card;
  };

  const buildAlbums = () => {
    const grouped = new Map();
    photos.forEach((photo) => {
      const title = photo.album || photo.title;
      const slug = photo.albumSlug || slugify(title);
      if (!grouped.has(slug)) {
        grouped.set(slug, {
          slug,
          title,
          date: photo.date,
          dateLabel: photo.dateLabel,
          week: photo.week || photo.date,
          year: photo.year,
          activity: photo.activity,
          photos: []
        });
      }
      grouped.get(slug).photos.push(photo);
    });
    albums = [...grouped.values()].sort((a, b) => b.date.localeCompare(a.date) || a.title.localeCompare(b.title));
  };

  const renderFeatured = () => {
    const latestWeek = albums.length ? albums[0].week : null;
    featuredList.replaceChildren(...albums.filter((album) => album.week === latestWeek).map((album) => makeAlbumCard(album, true)));
  };

  const renderArchive = () => {
    const query = search.value.trim().toLowerCase();
    const selectedYear = year.value;
    const selectedActivity = activity.value;
    const visible = albums.filter((album) => {
      const photoText = album.photos.map((photo) => `${photo.title} ${photo.caption}`).join(' ');
      const haystack = `${album.title} ${album.activity} ${album.year} ${photoText}`.toLowerCase();
      return (!query || haystack.includes(query))
        && (selectedYear === 'all' || String(album.year) === selectedYear)
        && (selectedActivity === 'all' || album.activity === selectedActivity);
    });
    const visiblePhotos = visible.reduce((sum, album) => sum + album.photos.length, 0);
    status.textContent = `Showing ${visible.length} album${visible.length === 1 ? '' : 's'} containing ${visiblePhotos} photo${visiblePhotos === 1 ? '' : 's'}`;
    archiveList.replaceChildren();
    if (!visible.length) {
      const empty = document.createElement('p');
      empty.className = 'photo-empty';
      empty.textContent = 'No photo albums match those filters.';
      archiveList.append(empty);
      return;
    }
    archiveList.append(...visible.map((album) => makeAlbumCard(album)));
  };

  const renderAlbum = (slug) => {
    const album = albums.find((candidate) => candidate.slug === slug);
    if (!album) return false;
    indexView.hidden = true;
    albumView.hidden = false;
    albumView.querySelector('[data-album-title]').textContent = album.title;
    albumView.querySelector('[data-album-meta]').textContent = `${formatDate(album)} · ${album.activity} · ${album.photos.length} photo${album.photos.length === 1 ? '' : 's'}`;
    albumView.querySelector('[data-album-grid]').replaceChildren(...album.photos.map(makePhotoCard));
    document.title = `${album.title} | Collegians Harriers Photos`;
    return true;
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
      buildAlbums();
      total.textContent = photos.length;
      [...new Set(albums.map((album) => album.year))].sort((a, b) => b - a).forEach((value) => year.add(new Option(String(value), String(value))));
      [...new Set(albums.map((album) => album.activity))].sort().forEach((value) => activity.add(new Option(value, value)));

      const requestedAlbum = new URLSearchParams(window.location.search).get('album');
      if (requestedAlbum && renderAlbum(requestedAlbum)) return;

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
