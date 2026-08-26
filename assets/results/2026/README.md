# 2026 approved result files

Store final, approved 2026 result PDFs in this directory.

The recommended workflow is to place approved PDFs in `results-inbox/` and run `Publish Results.cmd`. The publisher moves each file here and updates `assets/data/results.json` automatically.

For a manual update, add the PDF here and then add its public record to `assets/data/results.json`. The Results page reads that register automatically, sorts entries newest first and creates category filters from the published records.

Use lowercase, hyphenated filenames in this format:

```text
YYYY-MM-DD-event-or-series-results.pdf
```

Do not store draft, private or unapproved result files here.
