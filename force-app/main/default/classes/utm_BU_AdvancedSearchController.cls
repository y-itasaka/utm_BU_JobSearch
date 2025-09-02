public with sharing class utm_BU_AdvancedSearchController {

    @AuraEnabled(cacheable=true)
    public static List<JobOffer_BU__c> utm_BU_searchJobs(
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
        String query = 'SELECT Id, Name, PRPR_point3__c, CompanyInformation__c, Characteristics__c, Welfare__c, ' +
                       'WorkLocation__c, EmploymentStatus__c, Salary__c, QualificationRequirements__c, Destination__c, ' +
                       'RecruitmentReception__c, Number__c, EyeCatchImage__c, eyecatch_url__c, ' +
                       'joboffer__r.Field1702__c, joboffer__r.Field1624__c, joboffer__r.BusinessContent__c, ' +
                       'joboffer__r.BusinessContent_sub__c, joboffer__r.Field1619__c, joboffer__r.Field1734__c, ' +
                       'joboffer__r.Field1660__c, joboffer__r.Field1663__c, joboffer__r.Field1908__c, ' +
                       'joboffer__r.Salary01__c, joboffer__r.Field1591__c, joboffer__r.Field1585__c, joboffer__r.Field1608__c, joboffer__r.SeishainTouyou_Base__c ' +
                       'FROM JobOffer_BU__c ';

        List<String> conditions = new List<String>();

        if (String.isNotBlank(keyword)) {
            // 正規化：全角スペース・全角or・句読点を半角に変換
            String normalized = keyword
                .replaceAll('　', ' ')
                .replaceAll('[ｏｒＯＲ]', 'or')
                .replaceAll('[、。．，｡､]', ' ')
                .toLowerCase()
                .trim();
        
            List<String> tokens = normalized.split('\\s+');
            List<String> andConditions = new List<String>();
            List<String> orGroup = new List<String>();
        
            for (Integer i = 0; i < tokens.size(); i++) {
                String token = tokens[i].trim();
        
                if (token == 'or') {
                    continue; // スキップ
                }
        
                // 前後に "or" がある → ORグループ要素とみなす
                Boolean prevIsOr = (i > 0 && tokens[i - 1] == 'or');
                Boolean nextIsOr = (i < tokens.size() - 1 && tokens[i + 1] == 'or');
        
                if (prevIsOr || nextIsOr) {
                    orGroup.add(token);
                } else {
                    if (!orGroup.isEmpty()) {
                        andConditions.add('(' + buildOrCondition(orGroup) + ')');
                        orGroup.clear();
                    }
                    andConditions.add('(' + buildOrCondition(new List<String>{token}) + ')');
                }
            }
        
            // 残ったORグループを追加
            if (!orGroup.isEmpty()) {
                andConditions.add('(' + buildOrCondition(orGroup) + ')');
            }
        
            if (!andConditions.isEmpty()) {
                conditions.add(String.join(andConditions, ' AND '));
            }
        }
        




        // 3. 休日
        if (holidays != null && !holidays.isEmpty()) {
            List<String> holidayConds = new List<String>();
            for (String h : holidays) {
                if (h == '土') {
                    holidayConds.add('joboffer__r.Field1908__c INCLUDES (\'土\', \'土（隔週）\')');
                } else {
                    holidayConds.add('joboffer__r.Field1908__c INCLUDES (\'' + String.escapeSingleQuotes(h) + '\')');
                }
            }
            conditions.add(String.join(holidayConds, ' AND '));
        }

        // 4. 働き方
        if (workStyles != null && !workStyles.isEmpty()) {
            for (String s : workStyles) {
                if (s == '正社員') conditions.add('joboffer__r.Field1688__c = true');
                if (s == '軽作業') conditions.add('joboffer__r.Field1685__c = true');
                if (s == '未経験OK') conditions.add('joboffer__r.OK__c = true');
                if (s == '扶養内') conditions.add('joboffer__r.Field1623__c = true');
                if (s == 'シニア') conditions.add('joboffer__r.Field1687__c = true');
            }
        }

        // 5. 時給
        if (minWage != null) {
            conditions.add('joboffer__r.Field1619__c >= :minWage');
        }
        if (maxWage != null) {
            conditions.add('joboffer__r.Field1619__c <= :maxWage');
        }

        // 6. WHERE句をまとめて追加
        if (!conditions.isEmpty()) {
            query += ' WHERE ' + String.join(conditions, ' AND ');
        }

        // 7. LIMIT
        query += ' LIMIT 200';

        // 8. 実行
        List<JobOffer_BU__c> offers = Database.query(query);

        // 9. 勤務時間フィルター
        if (String.isNotBlank(startTimeStr) || String.isNotBlank(endTimeStr)) {
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

            List<JobOffer_BU__c> filtered = new List<JobOffer_BU__c>();
            for (JobOffer_BU__c o : offers) {
                Time jobStart = o.joboffer__r.Field1660__c;
                Time jobEnd = o.joboffer__r.Field1663__c;

                if (jobStart == null || jobEnd == null) continue;

                Boolean isNightShift = jobEnd < jobStart;
                Boolean keep = true;

                if (startTime != null && endTime != null) {
                    if (endTime > startTime) {
                        if (isNightShift) {
                            keep = false;
                        } else {
                            keep = (jobStart >= startTime && jobEnd <= endTime);
                        }
                    } else {
                        keep = (jobStart >= startTime || jobStart <= endTime) &&
                               (jobEnd >= startTime || jobEnd <= endTime);
                    }
                } else if (startTime != null) {
                    keep = jobStart >= startTime;
                } else if (endTime != null) {
                    keep = jobEnd <= endTime;
                }

                if (keep) {
                    filtered.add(o);
                }
            }

            offers = filtered;
        }

        return offers;
    }

    // 🔧 OR条件の部分一致クエリを構築する補助関数
    public static String buildOrCondition(List<String> words) {
        List<String> orConditions = new List<String>();
        for (String word : words) {
            String escaped = String.escapeSingleQuotes(word);
            List<String> sub = new List<String>();
            for (String f : new List<String>{
                'Name', 'PRPR_point3__c', 'CompanyInformation__c', 'Characteristics__c',
                'Welfare__c',  'WorkLocation__c', 'EmploymentStatus__c',
                'Salary__c', 'QualificationRequirements__c', 'Destination__c',
                'RecruitmentReception__c', 'Number__c'
            }) {
                sub.add(f + ' LIKE \'%' + escaped + '%\'');
            }
            orConditions.add('(' + String.join(sub, ' OR ') + ')');
        }
        return String.join(orConditions, ' OR ');
    }
    
    
}
