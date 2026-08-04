// One-time script to register the nightly Lead auto-close job.
// Run once per org after deployment:
//     SFDX: Execute Anonymous Apex with Editor Contents
// Re-running is safe only after the existing job is deleted first
// (System.schedule throws if a job with the same name is already scheduled).

String jobName = 'Lead Auto Close Nightly Job';
String cronExpression = '0 0 2 * * ?'; // Nightly at 2:00 AM

System.schedule(jobName, cronExpression, new LeadAutoCloseScheduler());
