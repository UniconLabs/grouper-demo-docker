GrouperSession.startRootSession()

addMember("etc:sysadmingroup","banderson");

addRootStem("psp","psp");

addRootStem("loader","loader");

addGroup("loader","allUsers", "All Users");

groupAddType("loader:allUsers", "grouperLoader");
setGroupAttr("loader:allUsers", "grouperLoaderDbName", "grouper");
setGroupAttr("loader:allUsers", "grouperLoaderType", "SQL_SIMPLE");
setGroupAttr("loader:allUsers", "grouperLoaderScheduleType", "CRON");
setGroupAttr("loader:allUsers", "grouperLoaderQuartzCron", "0 * * * * ?");
setGroupAttr("loader:allUsers", "grouperLoaderQuery", "select distinct uid as SUBJECT_ID from SIS_COURSES");

addGroup("loader","coursesLoader", "Course Loader");
groupAddType("loader:coursesLoader", "grouperLoader");
setGroupAttr("loader:coursesLoader", "grouperLoaderDbName", "grouper");
setGroupAttr("loader:coursesLoader", "grouperLoaderType", "SQL_GROUP_LIST");
setGroupAttr("loader:coursesLoader", "grouperLoaderScheduleType", "CRON");
setGroupAttr("loader:coursesLoader", "grouperLoaderQuartzCron", "0 * * * * ?");
setGroupAttr("loader:coursesLoader", "grouperLoaderQuery", "select distinct uid as SUBJECT_ID, CONCAT('courses:', courseID) as GROUP_NAME from SIS_COURSES");
