# Results inbox

This is the drop folder for approved result PDFs.

## Publish results

1. Confirm that each PDF is final and approved for public release.
2. Name each file with its date first, for example:

   ```text
   2026-08-25-tuesday-time-trial-results.pdf
   ```

3. Copy the PDFs into this `results-inbox` folder.
4. Double-click `Publish Results.cmd` in the website's main folder.
5. Review or enter the title, category and optional note for each file.
6. Choose whether to publish the prepared files to the `develop` preview immediately.
7. Check the live Results page after GitHub Pages finishes.

The publisher moves approved files into the correct year folder and updates `assets/data/results.json`. PDFs left in this inbox are deliberately ignored by Git so they cannot be published accidentally.

Only PDF files are accepted. The publisher never overwrites an existing published filename.

The approved PDF remains the source document. If an HTML result page is created from it, register that page with the optional `-PagePath` setting. The Results card will open the mobile-friendly HTML page first and retain the PDF as a secondary link. This can be used for weekly time trials, road or trail races, championships and hosted events.

Choose the category that matches the file:

- **Time trial** for weekly Herman's Delight or other club time trials
- **Road** for road-race results
- **Trail** for trail-race results
- **Championship** for club championship logs or standings
- **Hosted event** for results from a Collegians-hosted event
