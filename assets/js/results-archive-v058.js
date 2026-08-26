(() => {
  const archive = document.querySelector('[data-results-archive]');
  if (!archive) return;

  const list = archive.querySelector('[data-archive-list]');
  const status = archive.querySelector('[data-archive-status]');
  const totals = archive.querySelectorAll('[data-archive-total]');
  const search = archive.querySelector('[data-archive-search]');
  const year = archive.querySelector('[data-archive-year]');
  const category = archive.querySelector('[data-archive-category]');
  const source = archive.dataset.source;
  const currentSource = archive.dataset.currentSource;
  const allowedCategories = (archive.dataset.archiveCategories || '')
    .split(',')
    .map((value) => value.trim())
    .filter(Boolean);
  const seasonsTotal = archive.querySelector('[data-archive-seasons]');
  const latest = archive.querySelector('[data-archive-latest]');
  const categoryLabels = {
    'time-trial': 'Time trial',
    road: 'Road race',
    trail: 'Trail race',
    championship: 'Championship',
    'hosted-event': 'Hosted event'
  };
  let records = [];

  const formatDate = (value) => {
    const parsed = new Date(`${value}T12:00:00`);
    return Number.isNaN(parsed.getTime())
      ? value
      : new Intl.DateTimeFormat('en-ZA', { day: 'numeric', month: 'long', year: 'numeric' }).format(parsed);
  };

  const createItem = (record) => {
    const item = document.createElement('article');
    item.className = 'archive-item';
    const label = document.createElement('div');
    label.className = 'archive-category';
    label.textContent = categoryLabels[record.category] || record.category;
    const copy = document.createElement('div');
    const heading = document.createElement('h3');
    heading.textContent = record.title;
    const meta = document.createElement('p');
    meta.textContent = record.dateLabel || formatDate(record.date);
    copy.append(heading, meta);
    const link = document.createElement('a');
    link.href = record.page || record.file;
    if (!record.page) {
      link.target = '_blank';
      link.rel = 'noopener noreferrer';
    }
    link.textContent = record.page ? 'View HTML result' : 'Open PDF';
    link.setAttribute('aria-label', `${record.page ? 'View' : 'Open'} ${record.title}`);
    item.append(label, copy, link);
    return item;
  };

  const render = () => {
    const query = search.value.trim().toLowerCase();
    const selectedYear = year.value;
    const selectedCategory = category ? category.value : 'all';
    const visible = records.filter((record) => {
      const matchesQuery = !query || `${record.title} ${record.season} ${categoryLabels[record.category] || record.category}`.toLowerCase().includes(query);
      const matchesYear = selectedYear === 'all' || String(record.season) === selectedYear;
      const matchesCategory = selectedCategory === 'all' || record.category === selectedCategory;
      return matchesQuery && matchesYear && matchesCategory;
    });

    list.replaceChildren();
    status.textContent = `Showing ${visible.length} of ${records.length} archived result${records.length === 1 ? '' : 's'}`;
    if (!visible.length) {
      const empty = document.createElement('p');
      empty.className = 'archive-empty';
      empty.textContent = 'No archived results match those filters.';
      list.append(empty);
      return;
    }

    const years = [...new Set(visible.map((record) => record.season))].sort((a, b) => b - a);
    years.forEach((season) => {
      const yearRecords = visible.filter((record) => record.season === season);
      const section = document.createElement('section');
      section.className = 'archive-year';
      section.setAttribute('aria-labelledby', `archive-year-${season}`);
      const head = document.createElement('div');
      head.className = 'archive-year-head';
      const heading = document.createElement('h2');
      heading.id = `archive-year-${season}`;
      heading.textContent = season;
      const count = document.createElement('span');
      count.textContent = `${yearRecords.length} document${yearRecords.length === 1 ? '' : 's'}`;
      head.append(heading, count);
      const group = document.createElement('div');
      group.className = 'archive-list';
      group.append(...yearRecords.map(createItem));
      section.append(head, group);
      list.append(section);
    });
  };

  const loadRegister = (url) => fetch(url, { cache: 'no-store' }).then((response) => {
    if (!response.ok) throw new Error(`Results register returned ${response.status}`);
    return response.json();
  });

  Promise.all([loadRegister(source), currentSource ? loadRegister(currentSource) : Promise.resolve({ results: [] })])
    .then(([archiveData, currentData]) => {
      records = [...(currentData.results || []), ...(archiveData.results || [])]
        .filter((record) => record && record.title && record.date && record.season && record.category && (record.file || record.page))
        .filter((record) => !allowedCategories.length || allowedCategories.includes(record.category))
        .sort((a, b) => b.date.localeCompare(a.date) || a.title.localeCompare(b.title));
      const seasons = [...new Set(records.map((record) => record.season))].sort((a, b) => b - a);
      seasons.forEach((season) => year.add(new Option(String(season), String(season))));
      totals.forEach((total) => { total.textContent = records.length; });
      if (seasonsTotal) seasonsTotal.textContent = seasons.length;
      if (latest) latest.textContent = records.length ? formatDate(records[0].date) : '—';
      search.addEventListener('input', render);
      year.addEventListener('change', render);
      if (category) category.addEventListener('change', render);
      render();
    })
    .catch(() => {
      totals.forEach((total) => { total.textContent = '—'; });
      status.textContent = 'Archive register unavailable';
      const error = document.createElement('p');
      error.className = 'archive-error';
      error.textContent = 'The historical results archive could not be loaded. Please try again or contact the club.';
      list.replaceChildren(error);
    });
})();
