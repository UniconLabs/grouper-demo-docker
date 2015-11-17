gs = GrouperSession.startRootSession()

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


addRootStem("affiliations","affiliations");

folder = StemFinder.findByName(gs, "affiliations");
AttributeAssign attributeAssign = folder.getAttributeDelegate().addAttribute(RuleUtils.ruleAttributeDefName()).getAttributeAssign();
AttributeValueDelegate attributeValueDelegate = attributeAssign.getAttributeValueDelegate();
attributeValueDelegate.assignValue(RuleUtils.ruleActAsSubjectSourceIdName(), "g:isa");
attributeValueDelegate.assignValue(RuleUtils.ruleActAsSubjectIdName(), "GrouperSystem");
attributeValueDelegate.assignValue(RuleUtils.ruleCheckTypeName(), RuleCheckType.groupCreate.name());
attributeValueDelegate.assignValue(RuleUtils.ruleCheckStemScopeName(), Stem.Scope.SUB.name());
attributeValueDelegate.assignValue(RuleUtils.ruleThenElName(),"${ruleElUtils.assignGroupPrivilege(groupId, 'g:gsa', groupId, null, 'read')}");

group = new GroupSave(gs).assignName("loader:affiliationLoader").assignCreateParentStemsIfNotExist(true).save();
group.getAttributeDelegate().assignAttribute(LoaderLdapUtils.grouperLoaderLdapAttributeDefName()).getAttributeAssign();
attributeAssign = group.getAttributeDelegate().retrieveAssignment(null, LoaderLdapUtils.grouperLoaderLdapAttributeDefName(), false, true);
attributeAssign.getAttributeValueDelegate().assignValue(LoaderLdapUtils.grouperLoaderLdapQuartzCronName(), "0 * * * * ?");
attributeAssign.getAttributeValueDelegate().assignValue(LoaderLdapUtils.grouperLoaderLdapTypeName(), "LDAP_GROUPS_FROM_ATTRIBUTES");
attributeAssign.getAttributeValueDelegate().assignValue(LoaderLdapUtils.grouperLoaderLdapServerIdName(), "demo");
attributeAssign.getAttributeValueDelegate().assignValue(LoaderLdapUtils.grouperLoaderLdapFilterName(), "(eduPersonAffiliation=*)");
attributeAssign.getAttributeValueDelegate().assignValue(LoaderLdapUtils.grouperLoaderLdapSearchDnName(), "ou=People");
attributeAssign.getAttributeValueDelegate().assignValue(LoaderLdapUtils.grouperLoaderLdapSubjectAttributeName(), "uid");
attributeAssign.getAttributeValueDelegate().assignValue(LoaderLdapUtils.grouperLoaderLdapGroupAttributeName(), "eduPersonAffiliation");
attributeAssign.getAttributeValueDelegate().assignValue(LoaderLdapUtils.grouperLoaderLdapSubjectIdTypeName(), "subjectId");
attributeAssign.getAttributeValueDelegate().assignValue(LoaderLdapUtils.grouperLoaderLdapSubjectExpressionName(), "${subjectAttributes['subjectId']}");
attributeAssign.getAttributeValueDelegate().assignValue(LoaderLdapUtils.grouperLoaderLdapGroupNameExpressionName(), "affiliations:${groupAttribute}_systemOfRecord");
attributeAssign.getAttributeValueDelegate().assignValue(LoaderLdapUtils.grouperLoaderLdapGroupDisplayNameExpressionName(), "${groupAttribute} system of record");
attributeAssign.getAttributeValueDelegate().assignValue(LoaderLdapUtils.grouperLoaderLdapGroupTypesName(), "addIncludeExclude");

