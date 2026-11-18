/**
 * Job search setup: intake form update (v1 -> v2)
 *
 * Updates the existing form in place, so the link already sent to people keeps working.
 * Adds tick-box questions that use the same options as the company database
 * (sectors, focus areas, company type, size, job function) and aligns three existing
 * questions to those options (ways of working, level, contract type).
 *
 * How to use:
 * 1. Go to https://script.google.com and click "New project".
 * 2. Paste this whole file in, save, choose updateIntakeForm and click Run.
 * 3. Approve the permissions (it finds the form in your Drive and edits it).
 * 4. Check the Execution log: it lists each change. Safe to run twice.
 *
 * Only run this before anyone has answered the form: changing options on a form
 * with responses can make older answers harder to read.
 */

var FORM_NAME = 'Job search setup: your questions';

var SECTORS = [
  'Construction & civil engineering', 'Housebuilding & property development', 'Retrofit & energy efficiency',
  'Renewable energy & clean tech', 'Energy & utilities (incl. water)', 'Social housing & housing associations',
  'Facilities management & property services', 'Architecture, surveying & engineering consultancy',
  'Marine, ports & maritime', 'Transport & logistics', 'Aviation & aerospace', 'Automotive',
  'Software & SaaS', 'Fintech', 'AI & data', 'Cybersecurity', 'IT services & consultancy', 'Telecoms',
  'E-commerce & marketplaces',
  'Banking & insurance', 'Investment & asset management', 'Accounting, legal & consulting', 'Recruitment & HR services',
  'Central & local government', 'NHS & healthcare', 'Education & training', 'Charity & social enterprise',
  'Defence & security',
  'Manufacturing & engineering', 'Pharma, biotech & life sciences', 'Food, drink & agriculture',
  'Environmental services & waste',
  'Retail & consumer goods', 'Hospitality, events & leisure', 'Media, marketing & creative', 'Travel & tourism',
  'Any sector, if the role is right'
];
var FOCUS_AREAS = ['Climate & sustainability', 'Social impact', 'Health & wellbeing', 'Education & skills',
  'Financial inclusion', "Doesn't matter"];
var COMPANY_TYPES = ['Startup', 'Scale-up', 'Established SME', 'Large corporate', 'Public sector',
  'Charity or social enterprise', 'No preference'];
var SIZE_BANDS = ['1-49', '50-249', '250-999', '1,000-4,999', '5,000+', 'No preference'];
var JOB_FUNCTIONS = ['Project & programme management', 'Operations', 'Customer success & account management',
  'Sales & business development', 'Solutions & pre-sales', 'Marketing & communications', 'Product management',
  'Software engineering', 'Data & analytics', 'Design', 'Finance', 'HR & people', 'Administration & office support',
  'Sustainability & ESG', 'Surveying & site roles', 'Policy & research'];
var WORK_MODES = ['On-site', 'Hybrid', 'Remote (UK)', 'Remote (anywhere)'];
var LEVELS = ['Trainee or entry', 'Assistant or junior', 'Coordinator, officer or specialist', 'Manager',
  'Senior manager or lead', 'Head of or director', 'Executive'];
var CONTRACTS = ['Permanent full time', 'Permanent part time', 'Fixed-term', 'Contract or freelance', 'Temporary',
  'Apprenticeship or graduate scheme'];

function updateIntakeForm() {
  var form = findForm_();
  Logger.log('Updating: ' + form.getTitle() + ' (' + form.getEditUrl() + ')');
  if (form.getResponses().length > 0) {
    Logger.log('WARNING: this form already has ' + form.getResponses().length + ' response(s). Options were still updated.');
  }

  // 1. Job functions, right after job titles
  addCheckboxAfter_(form, 'Which job titles are you aiming for?',
    'Which kinds of work are you looking for?',
    'Tick any that apply. This helps when job titles vary between companies.',
    JOB_FUNCTIONS, false, null, true);

  // 2. Sectors as tick boxes, then the old free-text question becomes the "more detail" box
  addCheckboxAfter_(form, 'Which kinds of work are you looking for?',
    'Which sectors interest you?',
    'Tick up to five, or "Any sector" if the role matters more than the industry.',
    SECTORS, true, 5, true);

  var oldSectors = findItem_(form, 'Which sectors or industries do you want to work in?');
  if (oldSectors) {
    oldSectors.asParagraphTextItem()
      .setTitle('Anything more specific about the sectors or kind of work you want?')
      .setHelpText('For example "social housing retrofit, not commercial fit-out" or "B2B SaaS, not consumer apps".')
      .setRequired(false);
    Logger.log('Renamed the free-text sectors question.');
  }

  // 3. What the company works on
  addCheckboxAfter_(form, 'Anything more specific about the sectors or kind of work you want?',
    'Does it matter to you what a company works on?',
    'Tick any that matter, or "Doesn\'t matter".',
    FOCUS_AREAS, false, null, false);

  // 4. Company type and size, after the "avoid" question
  addCheckboxAfter_(form, 'Are there sectors, types of work or employers you want to avoid?',
    'What kind of company would you like to work for?',
    'Tick any you would consider.',
    COMPANY_TYPES, false, null, false);
  addCheckboxAfter_(form, 'What kind of company would you like to work for?',
    'What size of company?',
    'Number of staff. Tick any you would consider.',
    SIZE_BANDS, false, null, false);

  // 5. Align existing questions to the shared lists
  setChoices_(form, 'Which ways of working suit you?', WORK_MODES);
  setChoices_(form, 'Which levels would you consider?', LEVELS);
  setChoices_(form, 'Which contract types are you open to?', CONTRACTS);

  Logger.log('Done. The form link is unchanged: ' + form.getPublishedUrl());
}

// ---------- helpers ----------
function findForm_() {
  var files = DriveApp.getFilesByName(FORM_NAME);
  while (files.hasNext()) {
    var f = files.next();
    if (f.getMimeType() === MimeType.GOOGLE_FORMS && !f.isTrashed()) return FormApp.openById(f.getId());
  }
  throw new Error('Could not find a form called "' + FORM_NAME + '" in your Drive.');
}

function findItem_(form, title) {
  var items = form.getItems();
  for (var i = 0; i < items.length; i++) if (items[i].getTitle() === title) return items[i];
  return null;
}

function addCheckboxAfter_(form, anchorTitle, title, help, options, required, maxPicks, withOther) {
  if (findItem_(form, title)) { Logger.log('Already there, skipped: ' + title); return; }
  var anchor = findItem_(form, anchorTitle);
  if (!anchor) throw new Error('Could not find the question "' + anchorTitle + '".');
  var item = form.addCheckboxItem().setTitle(title).setHelpText(help)
    .setChoiceValues(options).setRequired(!!required);
  if (withOther) item.showOtherOption(true);
  if (maxPicks) item.setValidation(FormApp.createCheckboxValidation().requireSelectAtMost(maxPicks).build());
  form.moveItem(item.getIndex(), anchor.getIndex() + 1);
  Logger.log('Added: ' + title);
}

function setChoices_(form, title, options) {
  var item = findItem_(form, title);
  if (!item) { Logger.log('Not found, skipped: ' + title); return; }
  item.asCheckboxItem().setChoiceValues(options);
  Logger.log('Updated options: ' + title);
}
