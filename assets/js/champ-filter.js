(() => {
  const form = document.querySelector('[data-champ-filters]');
  if (!form) return;

  const searchInput = form.querySelector('[data-champ-search]');
  const categorySelect = form.querySelector('[data-champ-category]');
  const status = document.querySelector('[data-champ-status]');
  const sections = [...document.querySelectorAll('[data-champ-section]')];

  const apply = () => {
    const term = searchInput.value.trim().toLowerCase();
    const category = categorySelect.value;
    let totalVisible = 0;
    let totalRows = 0;

    sections.forEach((section) => {
      const rows = [...section.querySelectorAll('[data-champ-body] tr')];
      const empty = section.querySelector('[data-champ-empty]');
      let visible = 0;
      rows.forEach((row) => {
        const matchesName = !term || row.dataset.name.includes(term);
        const matchesCategory = category === 'all' || row.dataset.category === category;
        const show = matchesName && matchesCategory;
        row.hidden = !show;
        if (show) visible += 1;
      });
      if (empty) empty.hidden = visible !== 0;
      const count = section.querySelector('[data-champ-count]');
      if (count) {
        const total = Number(count.dataset.total || rows.length);
        count.textContent = term || category !== 'all'
          ? `${visible} of ${total} runners match`
          : `${total} runners logged this season.`;
      }
      totalVisible += visible;
      totalRows += rows.length;
    });

    status.textContent = term || category !== 'all'
      ? `Showing ${totalVisible} of ${totalRows} runners across all categories.`
      : '';
  };

  searchInput.addEventListener('input', apply);
  categorySelect.addEventListener('change', apply);
  apply();
})();
