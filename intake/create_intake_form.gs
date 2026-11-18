/**
 * Job search setup: intake form (v1, used for the MVP test users)
 *
 * How to use:
 * 1. Go to https://script.google.com and click "New project".
 * 2. Delete the sample code, paste this whole file in, and save.
 * 3. Choose createIntakeForm in the function list at the top and click Run.
 * 4. Approve the permissions (it only creates a form and a sheet in your Drive).
 * 5. Open View → Logs (or Execution log) for the form link to send and the edit link.
 *
 * Then run update_intake_form_v2.gs to add the company questions (shared lists).
 *
 * File uploads are not included: Google Forms uploads need the respondent to sign in
 * and can't be created by script. Ask for the CV and LinkedIn PDF by email instead.
 */

function createIntakeForm() {
  var form = FormApp.create('Job search setup: your questions');
  form.setDescription(
    'Thanks for trying this out. Your answers set up three things: your CV, a LinkedIn guide, ' +
    'and a daily email of jobs that match what you want.\n\n' +
    'It takes about 25 minutes. Rough answers are fine, and you can leave anything you are unsure about blank. ' +
    'Before anything is written, you will get a one-page summary of your search plan to check and correct.\n\n' +
    'Separately, please email your current CV and a PDF of your LinkedIn profile ' +
    '(LinkedIn: Me → View profile → Resources → Save to PDF).'
  );
  form.setProgressBar(true);
  form.setAllowResponseEdits(true);
  form.setConfirmationMessage(
    'Thanks! You will get a one-page summary of your search plan to check before anything is built. ' +
    'If you have not sent your CV and LinkedIn PDF yet, please email them now.'
  );

  // ---------- 1. About you ----------
  form.addSectionHeaderItem().setTitle('About you'); // first page, so no page break
  text(form, 'Full name', '', true);
  text(form, 'Email address for your daily job email', '', true);
  text(form, 'Where do you live?', 'Town or city, and the first part of your postcode (for example, Islington, N1).', true);

  // ---------- 2. Direction ----------
  section(form, 'What you are looking for', 'This decides which jobs we search for and how they are scored.');
  para(form, 'Which job titles are you aiming for?',
    'List as many as you like, most wanted first. Include variations (for example, "project coordinator, project officer").', true);
  para(form, 'Which sectors or industries do you want to work in?', '', true);
  para(form, 'Are there sectors, types of work or employers you want to avoid?',
    'For example, a sector you are leaving, or types of work you never want to see.', false);
  choice(form, 'How does this compare with what you do now?', [
    'Same kind of role and sector',
    'Moving to a related role or sector',
    'Changing sector completely'
  ], true);
  choice(form, 'How many years of experience do you have in the sector you are targeting?', [
    'None yet', 'Less than 1 year', '1 to 3 years', '3 to 5 years', '5 to 10 years', 'More than 10 years'
  ], true);
  checks(form, 'Which levels would you consider?', [
    'Trainee or entry level',
    'Assistant, coordinator or officer',
    'Manager',
    'Senior manager',
    'Head of or director'
  ], true);
  choice(form, 'Would you take a more junior role to get into a new sector?', [
    'Yes', 'Only if training is offered', 'No'
  ], false);

  // ---------- 3. Location and pay ----------
  section(form, 'Location and pay', '');
  checks(form, 'Which ways of working suit you?', ['On-site', 'Hybrid', 'Fully remote'], true);
  para(form, 'Where would you work, and how far would you travel each day?',
    'For example, "Central and North London, up to 1 hour each way".', true);
  para(form, 'Would you move for the right job? If so, where?', '', false);
  para(form, 'What is the lowest salary you would accept in each location?',
    'For example, "London £40k, Manchester £32k, remote £35k". Jobs below this are filtered out. Jobs that do not show a salary are kept.', true);
  checks(form, 'Which contract types are you open to?', [
    'Permanent, full time', 'Permanent, part time', 'Fixed-term contract', 'Freelance or day rate', 'Temporary'
  ], true);
  choice(form, 'Will you need visa sponsorship to work in the UK?', ['No', 'Yes', 'Prefer not to say'], false);

  // ---------- 4. Qualifications ----------
  section(form, 'Qualifications', 'Jobs that ask for something you do not have are scored lower, unless they offer training.');
  para(form, 'Which qualifications, certifications or licences do you have?',
    'Include degrees, professional certificates and things like a driving licence if relevant.', false);
  para(form, 'Are you working towards anything, or planning to?', 'Include the expected finish date if you know it.', false);
  para(form, 'Which qualifications do job ads in your target area often ask for that you do not have yet?',
    '"Not sure" is a fine answer.', false);

  // ---------- 5. Dealbreakers and companies ----------
  section(form, 'Dealbreakers and companies', '');
  checks(form, 'Which of these would rule a job out for you?', [
    'A lot of travel',
    'Shifts, nights or weekends',
    'Ads from recruitment agencies',
    'Fixed-term contracts',
    'Commission-based pay'
  ], false, true);
  para(form, 'Are there companies you would love to work for?',
    'We can check their careers pages for you as well.', false);
  para(form, 'Are there companies you never want to see?', 'For example, your current or a past employer.', false);

  // ---------- 6. Your experience in numbers ----------
  section(form, 'Your experience in numbers',
    'Numbers make the biggest difference to a CV. We never make numbers up: everything on your CV will come from your CV or your answers here. ' +
    'Think team sizes, volumes (customers, projects, sites, events), budgets, money saved or earned, time saved, and results. Rough figures are fine.');
  para(form, 'Most recent role: job title, employer, and any numbers you can share', '', false);
  para(form, 'Role before that: job title, employer, and any numbers', '', false);
  para(form, 'Role before that: job title, employer, and any numbers', '', false);
  para(form, 'Is there anything you are proud of that is not on your CV?', '', false);
  para(form, 'Are there gaps, overlapping jobs or side businesses we should explain?',
    'For example, seasonal work, self-employment alongside a job, career breaks.', false);

  // ---------- 7. Your voice ----------
  section(form, 'Your voice', 'So your CV and LinkedIn sound like you, not like a template.');
  choice(form, 'How much should we change your writing?', [
    'Light edit: keep my wording where possible and show me what changed',
    'Full rewrite: start fresh'
  ], true);
  para(form, 'Paste two or three short things you have written yourself',
    'Emails, messages or a cover letter you liked. Please not AI-written. Remove anything private.', false);
  para(form, 'Are there words or phrases you never want on your CV?', 'For example, "passionate", "synergy".', false);

  // ---------- 8. Daily email and consent ----------
  section(form, 'Your daily job email', '');
  choice(form, 'When should your daily job email arrive?', ['7am', '8am', '9am', 'Midday'], true);
  para(form, 'Anything else we should know?', '', false);
  form.addCheckboxItem()
    .setTitle('Your data')
    .setHelpText('Your CV and answers are used only to create your documents and job email. They are stored securely and deleted when you ask.')
    .setChoiceValues(['I agree to my CV and answers being used and stored this way'])
    .setRequired(true);
  choice(form, 'Can an anonymised version of your results be used as a case study?',
    ['Yes', 'Ask me first', 'No'], true);

  // ---------- Responses sheet ----------
  var sheet = SpreadsheetApp.create('Job search setup: intake responses');
  form.setDestination(FormApp.DestinationType.SPREADSHEET, sheet.getId());

  // Forms created by script may start unpublished.
  try { form.setPublished(true); } catch (e) { /* older behaviour: already published */ }

  Logger.log('Form link to send: ' + form.getPublishedUrl());
  Logger.log('Edit the form here: ' + form.getEditUrl());
  Logger.log('Responses sheet: ' + sheet.getUrl());
}

// ---------- helpers ----------
function section(form, title, help) {
  var item = form.addPageBreakItem().setTitle(title);
  if (help) item.setHelpText(help);
}
function text(form, title, help, required) {
  var item = form.addTextItem().setTitle(title).setRequired(!!required);
  if (help) item.setHelpText(help);
}
function para(form, title, help, required) {
  var item = form.addParagraphTextItem().setTitle(title).setRequired(!!required);
  if (help) item.setHelpText(help);
}
function choice(form, title, options, required) {
  form.addMultipleChoiceItem().setTitle(title).setChoiceValues(options).setRequired(!!required);
}
function checks(form, title, options, required, withOther) {
  var item = form.addCheckboxItem().setTitle(title).setChoiceValues(options).setRequired(!!required);
  if (withOther) item.showOtherOption(true);
}
