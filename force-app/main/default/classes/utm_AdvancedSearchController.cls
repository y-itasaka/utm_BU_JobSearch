public with sharing class utm_AdvancedSearchController {
    @AuraEnabled(cacheable=true)
    public static List<Job_Offer__c> utm_searchJobs(
        String keyword,
        List<String> jobTypes,
        List<String> holidays,
        List<String> workStyles,
        List<String> employmentTypes,
        Decimal minWage,
        Decimal maxWage,
        String startTimeStr,
        String endTimeStr
        ) {
        String query = 'SELECT Id, Name, PR_point3__c, CompanyInformation__c, Characteristics__c, Welfare__c, AverageAge__c, ' +
                       'WorkLocation__c, EmploymentStatus__c, Salary__c, QualificationRequirements__c, Destination__c, ' +
                       'RecruitmentReception__c, Number__c, EyeCatchImage__c, eyecatch_url__c, ' +
                       'joboffer__r.Field1702__c, joboffer__r.Field1624__c, joboffer__r.BusinessContent__c, ' +
                       'joboffer__r.BusinessContent_sub__c, joboffer__r.Field1619__c, joboffer__r.Field1734__c, ' +
                       'joboffer__r.Field1660__c, joboffer__r.Field1663__c, joboffer__r.Field1908__c, joboffer__r.StartTime1__c, joboffer__r.EndTime1__c, ' +
                       'joboffer__r.Salary01__c, joboffer__r.Field1591__c, joboffer__r.Field1585__c, joboffer__r.Field1608__c, joboffer__r.SeishainTouyou_Base__c ' +
                       'FROM Job_Offer__c ';

        if (String.isNotBlank(keyword)) {
            String[] keywords = keyword.split('[\\s　]+');
            String searchCondition = '';
            for (Integer i = 0; i < keywords.size(); i++) {
                if (i > 0) searchCondition += ' AND ';
                String escaped = String.escapeSingleQuotes(keywords[i]);
                searchCondition += '(' +
                    'Name LIKE \'%' + escaped + '%\' OR ' +
                    'PR_point3__c LIKE \'%' + escaped + '%\' OR ' +
                    'CompanyInformation__c LIKE \'%' + escaped + '%\' OR ' +
                    'Characteristics__c LIKE \'%' + escaped + '%\' OR ' +
                    'Welfare__c LIKE \'%' + escaped + '%\' OR ' +
                    'AverageAge__c LIKE \'%' + escaped + '%\' OR ' +
                    'WorkLocation__c LIKE \'%' + escaped + '%\' OR ' +
                    'EmploymentStatus__c LIKE \'%' + escaped + '%\' OR ' +
                    'Salary__c LIKE \'%' + escaped + '%\' OR ' +
                    'QualificationRequirements__c LIKE \'%' + escaped + '%\' OR ' +
                    'Destination__c LIKE \'%' + escaped + '%\' OR ' +
                    'RecruitmentReception__c LIKE \'%' + escaped + '%\' OR ' +
                    'Number__c LIKE \'%' + escaped + '%\')';
            }
            query += 'WHERE ' + searchCondition;
        }

        

        if (holidays != null && !holidays.isEmpty()) {
            String holidayFilter = '(';
            for (Integer i = 0; i < holidays.size(); i++) {
                if (holidays[i] == '土') {
                    holidayFilter += 'joboffer__r.Field1908__c INCLUDES (\'土\', \'土（隔週）\')';
                } else {
                    holidayFilter += 'joboffer__r.Field1908__c INCLUDES (\'' + String.escapeSingleQuotes(holidays[i]) + '\')';
                }
                if (i < holidays.size() - 1) {
                    holidayFilter += ' AND ';
                }
            }
            holidayFilter += ')';
            query += query.contains('WHERE') ? ' AND ' : ' WHERE ';
            query += holidayFilter;
        }   

        

        
        
        // ✅ 条件保持用リストを宣言
            List<String> conditions = new List<String>();

            // ✅ 働き方のAND検索（5項目の文字列一致）
            if (workStyles != null && !workStyles.isEmpty()) {
                for (String style : workStyles) {
                    if (style == '正社員') {
                        conditions.add('joboffer__r.Field1688__c = true');
                    }
                    if (style == '軽作業') {
                        conditions.add('joboffer__r.Field1685__c = true');
                    }
                    if (style == '未経験OK') {
                        conditions.add('joboffer__r.OK__c = true');
                    }
                    if (style == '扶養内') {
                        conditions.add('joboffer__r.Field1623__c = true');
                    }
                    if (style == 'シニア') {
                        conditions.add('joboffer__r.Field1687__c = true');
                    }
                }
                if (!conditions.isEmpty()) {
                    query += query.contains('WHERE') ? ' AND ' : ' WHERE ';
                    query += String.join(conditions, ' AND ');
                }
            }


        if (minWage != null) {
            query += query.contains('WHERE') ? ' AND ' : ' WHERE ';
            query += 'joboffer__r.Field1619__c >= :minWage';
        }

        if (maxWage != null) {
            query += query.contains('WHERE') ? ' AND ' : ' WHERE ';
            query += 'joboffer__r.Field1619__c <= :maxWage';
        }

        if (startTimeStr != null || endTimeStr != null) {
            Time startTime = null;
            Time endTime = null;

            if (String.isNotBlank(startTimeStr)) {
                List<String> parts = startTimeStr.split(':');
                startTime = Time.newInstance(Integer.valueOf(parts[0]), Integer.valueOf(parts[1]), 0, 0);
            }
            if (String.isNotBlank(endTimeStr)) {
                List<String> parts = endTimeStr.split(':');
                endTime = Time.newInstance(Integer.valueOf(parts[0]), Integer.valueOf(parts[1]), 0, 0);
            }

            if (startTime != null && endTime != null) {
                if (endTime > startTime) {
                    query += ' AND (joboffer__r.Field1660__c >= :startTime AND joboffer__r.Field1660__c <= :endTime ' +
                             'AND joboffer__r.Field1663__c >= :startTime AND joboffer__r.Field1663__c <= :endTime)';
                } else {
                    query += ' AND ((joboffer__r.Field1660__c >= :startTime OR joboffer__r.Field1660__c <= :endTime) ' +
                             'AND (joboffer__r.Field1663__c >= :startTime OR joboffer__r.Field1663__c <= :endTime) ' +
                             'AND joboffer__r.Field1660__c <= joboffer__r.Field1663__c)';
                }
            } else if (startTime != null) {
                query += ' AND joboffer__r.Field1660__c >= :startTime';
            } else if (endTime != null) {
                query += ' AND joboffer__r.Field1663__c <= :endTime';
            }
        }

        query += ' LIMIT 102';
        System.debug('Generated Query: ' + query);
        return Database.query(query);
    }
}
