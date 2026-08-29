(() => {
  const library = document.querySelector('[data-results-library]');
  if (!library) return;

  const list = library.querySelector('[data-results-list]');
  const filters = library.querySelector('[data-results-filters]');
  const updated = library.querySelector('[data-results-updated]');
  const source = library.dataset.source;
  const categoryLabels = {
    'time-trial': 'Time trial',
    road: 'Road',
    trail: 'Trail',
    championship: 'Championship',
    'hosted-event': 'Hosted event'
  };
  let records = [];

  const formatDate = (value) => {
    const date = new Date(`${value}T12:00:00`);
    return Number.isNaN(date.getTime())
      ? value
      : new Intl.DateTimeFormat('en-ZA', { day: 'numeric', month: 'long', year: 'numeric' }).format(date);
  };

  const setMessage = (message, className) => {
    list.replaceChildren();
    const paragraph = document.createElement('p');
    paragraph.className = className;
    paragraph.textContent = message;
    list.append(paragraph);
  };

  const createResult = (record) => {
    const article = document.createElement('article');
    article.className = 'result-file';
    const category = document.createElement('div');
    category.className = 'result-file-category';
    category.textContent = categoryLabels[record.category] || record.category;
    const copy = document.createElement('div');
    const heading = document.createElement('h3');
    heading.textContent = record.title;
    const meta = document.createElement('p');
    meta.className = 'result-file-meta';
    meta.textContent = `${formatDate(record.date)} · ${record.season} season${record.note ? ` · ${record.note}` : ''}`;
    copy.append(heading, meta);
    const actions = document.createElement('div');
    actions.className = 'result-file-actions';
    const link = document.createElement('a');
    link.className = 'result-primary';
    link.href = record.page || record.file;
    link.textContent = record.page ? 'View results' : `Open ${record.format || 'result'}`;
    link.setAttribute('aria-label', record.page ? `View ${record.title} as an HTML page` : `Open ${record.title} ${record.format || 'result'}`);
    if (!record.page) {
      link.target = '_blank';
      link.rel = 'noopener noreferrer';
    }
    actions.append(link);
    if (record.page && record.file) {
      const pdfLink = document.createElement('a');
      pdfLink.className = 'result-secondary';
      pdfLink.href = record.file;
      pdfLink.target = '_blank';
      pdfLink.rel = 'noopener noreferrer';
      pdfLink.textContent = record.format || 'PDF';
      pdfLink.setAttribute('aria-label', `Open the original ${record.format || 'PDF'} for ${record.title}`);
      actions.append(pdfLink);
    }
    article.append(category, copy, actions);
    return article;
  };

  const render = (category = 'all') => {
    const visible = category === 'all' ? records : records.filter((record) => record.category === category);
    list.replaceChildren(...visible.map(createResult));
    if (!visible.length) setMessage('No approved result files are currently published in this category.', 'results-empty');
    filters.querySelectorAll('button').forEach((button) => {
      button.setAttribute('aria-pressed', String(button.dataset.category === category));
    });
  };

  const createFilters = () => {
    const categories = [...new Set(records.map((record) => record.category))];
    if (records.length < 2 || categories.length < 2) return;
    const options = ['all', ...categories];
    options.forEach((category) => {
      const button = document.createElement('button');
      button.type = 'button';
      button.className = 'results-filter';
      button.dataset.category = category;
      button.textContent = category === 'all' ? 'All results' : (categoryLabels[category] || category);
      button.setAttribute('aria-pressed', String(category === 'all'));
      button.addEventListener('click', () => render(category));
      filters.append(button);
    });
    filters.hidden = false;
  };

  fetch(source, { cache: 'no-store' })
    .then((response) => {
      if (!response.ok) throw new Error(`Results register returned ${response.status}`);
      return response.json();
    })
    .then((data) => {
      records = Array.isArray(data.results)
        ? data.results
            .filter((record) => record && record.title && record.date && record.category && record.file && record.season)
            .sort((a, b) => b.date.localeCompare(a.date))
        : [];
      updated.textContent = data.updated ? `Register updated ${formatDate(data.updated)}` : 'Awaiting the first approved result file';
      list.setAttribute('aria-busy', 'false');
      if (!records.length) {
        setMessage('No approved result files are currently published. New files will appear here with the latest result first.', 'results-empty');
        return;
      }
      createFilters();
      render();
    })
    .catch(() => {
      updated.textContent = 'Results register unavailable';
      list.setAttribute('aria-busy', 'false');
      setMessage('The results register could not be loaded. Please try again or contact the club.', 'results-error');
    });
})();
