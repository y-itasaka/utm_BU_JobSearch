import { LightningElement, track } from 'lwc';
import utm_searchJobs from '@salesforce/apex/utm_BU_AdvancedSearchController.utm_BU_searchJobs';



export default class UtmBUJobSearch extends LightningElement {
  @track keyword = '';
  @track selectedHolidays = [];
  @track minWage = 900;
  @track startTime = '';
  @track endTime = '';
  @track results = [];
  @track isNoResults = false;
  @track showFilters = false;
  @track selectedEmploymentTypes = [];
  @track selectedWorkStyles = [];
  @track summaryText = '働き方・休日・時給・時間';
  @track sortOption = 'wageDesc';
  @track currentPage = 1;
  @track pageSize = 25;
  @track hasSearched = false;

  
  
  
  //ページネーション
  get paginatedResults() {
    if (!this.results || this.results.length === 0) {
      return [];
    }
    const end = this.currentPage * this.pageSize;
    return this.results.slice(0, end);
  }
  

  get hasMoreResults() {
    return this.results.length > this.paginatedResults.length;
  }

  handleLoadMore() {
    this.currentPage++;
  }


  get sortOptions() {
    return [
      { label: '時給が高い', value: 'wageDesc' },
      { label: '開始時間が早い', value: 'startTimeAsc' },
      { label: '開始時間が遅い', value: 'startTimeDesc' },
      { label: '終了時間が早い', value: 'endTimeAsc' },
      { label: '終了時間が遅い', value: 'endTimeDesc' }
    ];
  }

  connectedCallback() {

    
    const path = window.location.pathname;
    const match = path.match(/\/global-search\/([^\/]+)/);
    if (match) {
      const keywordFromPath = decodeURIComponent(match[1]);
      this.keyword = keywordFromPath;
      this.handleSearch();
    }
    document.addEventListener('touchstart', this.preventTouchScrollOnSlider, { passive: false });
  }

  disconnectedCallback() {
    document.removeEventListener('touchstart', this.preventTouchScrollOnSlider);
  }

  preventTouchScrollOnSlider = (e) => {
    if (e.target?.type === 'range') {
      e.preventDefault();
    }
  }

  toggleFilters() {
    this.showFilters = !this.showFilters;
  }
  
  closeFilters() {
    this.showFilters = false;
    this.hasSearched = false; // ← 🔥検索結果全体を非表示にするため追加！
  }
  

  handleSearchAndClose() {
    this.updateSummaryText();
    this.handleSearch();
    this.toggleFilters();
  }

  handleModalBackdropClick() {
    this.toggleFilters();
  }

  stopPropagation(event) {
    event.stopPropagation();
  }

  handleKeyDown(event) {
    if (event.key === 'Enter') {
      event.preventDefault();
      this.handleSearch();
    }
  }

  handleKeywordChange(e) {
    this.keyword = e.target.value;
  }

  handleMinWageChangeCustom(e) {
    this.minWage = parseInt(e.target.value, 10);
    this.updateSummaryText();
  }

  handleStartTimeChange(e) {
    this.startTime = e.target.value;
    this.updateSummaryText();
  }

  handleEndTimeChange(e) {
    this.endTime = e.target.value;
    this.updateSummaryText();
  }

  clearKeyword() {
    this.keyword = '';
  }

  get hasResultsOrNoResults() {
    return this.hasSearched && (this.results.length > 0 || this.isNoResults);

    
  }
 

  handleClearAll() {
    this.keyword = '';
    this.selectedHolidays = [];
    this.minWage = 900;
    this.startTime = '';
    this.endTime = '';
    this.selectedEmploymentTypes = [];
    this.selectedWorkStyles = [];
    this.isNoResults = false;
    this.updateSummaryText();
    this.results = []; // ✅ 検索結果リセット
    this.currentPage = 1; // ✅ ページも戻す
    this.hasSearched = false; // ✅ 検索状態リセット

  }

  handleWorkStyleCheckboxChange(e) {
    const value = e.target.value;
    if (e.target.checked) {
      if (!this.selectedWorkStyles.includes(value)) {
        this.selectedWorkStyles = [...this.selectedWorkStyles, value];
      }
    } else {
      this.selectedWorkStyles = this.selectedWorkStyles.filter(v => v !== value);
    }
    this.updateSummaryText();
  }

  handleHolidayCheckboxChange(e) {
    const value = e.target.value;
    if (e.target.checked) {
      if (!this.selectedHolidays.includes(value)) {
        this.selectedHolidays = [...this.selectedHolidays, value];
      }
    } else {
      this.selectedHolidays = this.selectedHolidays.filter(v => v !== value);
    }
    this.updateSummaryText();
  }

  handleEmploymentCheckboxChange(e) {
    const value = e.target.value;
    if (e.target.checked) {
      if (!this.selectedEmploymentTypes.includes(value)) {
        this.selectedEmploymentTypes = [...this.selectedEmploymentTypes, value];
      }
    } else {
      this.selectedEmploymentTypes = this.selectedEmploymentTypes.filter(v => v !== value);
    }
  }

  get formattedMinWage() {
    return this.minWage.toLocaleString();
  }

  handleSearch() {
    this.hasSearched = true; // ← ✅ 検索済みフラグをここで立てる！
  
    utm_searchJobs({
      keyword: this.keyword,
      holidays: this.selectedHolidays,
      workStyles: this.selectedWorkStyles,
      employmentTypes: this.selectedEmploymentTypes,
      minWage: this.minWage,
      startTimeStr: this.startTime,
      endTimeStr: this.endTime
    })
    .then(result => {
      this.results = result.map(job => {
        const salaryMin = job.joboffer__r?.Salary01__c;
        const salaryMax = job.joboffer__r?.Field1591__c;
        const start = job.joboffer__r?.Field1660__c;
        const end = job.joboffer__r?.Field1663__c;
  
        const formatTime = (raw) => {
          const ms = Number(raw);
          if (isNaN(ms)) return '';
          const totalMinutes = ms / (1000 * 60);
          const hours = Math.floor(totalMinutes / 60);
          const minutes = totalMinutes % 60;
          return `${String(hours).padStart(2, '0')}:${String(minutes).padStart(2, '0')}`;
        };
  
        const holidays = job.joboffer__r?.Field1908__c
          ? job.joboffer__r.Field1908__c.replace(/;/g, '')
          : '';
  
        return {
          ...job,
          formattedSalaryMin: salaryMin ? Number(salaryMin).toLocaleString() : '',
          formattedSalaryMax: salaryMax ? Number(salaryMax).toLocaleString() : '',
          formattedStartTime: formatTime(start),
          formattedEndTime: formatTime(end),
          formattedHoliday: holidays
        };
      });
  
      this.sortResults();
      this.isNoResults = this.results.length === 0;
      

    })
    .catch(error => {
      console.error('検索エラー:', error);
    });
  }
  

  handleSortChangeNative(event) {
    this.sortOption = event.target.value;
  
    if (Array.isArray(this.results) && this.results.length > 0) {
      this.sortResults(); // ✅ 結果があるときだけ並び替えsfdx project deploy start --source-dir force-app/main/default/lwc/utmJobSearch


    }
  }
  

  sortResults() {
    const getTime = (val) => {
      const match = typeof val === 'string' ? val.match(/^(\d{2}):(\d{2})/) : null;
      if (match) {
        return parseInt(match[1], 10) * 60 + parseInt(match[2], 10);
      }
      return null;
    };

    this.results = [...this.results].sort((a, b) => {
      const aStart = getTime(a.formattedStartTime);
      const bStart = getTime(b.formattedStartTime);
      const aEnd = getTime(a.formattedEndTime);
      const bEnd = getTime(b.formattedEndTime);
      const aWage = a.joboffer__r?.Salary01__c || 0;
      const bWage = b.joboffer__r?.Salary01__c || 0;

      switch (this.sortOption) {
        case 'wageDesc':
          return bWage - aWage;
        case 'startTimeAsc':
          return aStart - bStart;
        case 'startTimeDesc':
          return bStart - aStart;
        case 'endTimeAsc':
          return aEnd - bEnd;
        case 'endTimeDesc':
          return bEnd - aEnd;
        default:
          return 0;
      }
    });
  }

  updateSummaryText() {
    const hasCondition =
      this.selectedWorkStyles.length > 0 ||
      this.selectedHolidays.length > 0 ||
      this.minWage > 900 ||
      this.startTime ||
      this.endTime;

    if (!hasCondition) {
      this.summaryText = '働き方・休日・時給・時間';
      return;
    }

    const workStyles = this.selectedWorkStyles.join('、');
    const holidays = this.selectedHolidays.join('');
    const wage = this.minWage > 900 ? `${this.minWage.toLocaleString()}円以上` : '';

    let time = '';
    if (this.startTime && this.endTime) {
      time = `${this.startTime.slice(0, 5)}〜${this.endTime.slice(0, 5)}`;
    } else if (this.startTime) {
      time = `${this.startTime.slice(0, 5)}〜`;
    } else if (this.endTime) {
      time = `〜${this.endTime.slice(0, 5)}`;
    }

    const parts = [workStyles, holidays, wage, time].filter(p => p);
    this.summaryText = parts.join('、');
  }

  get isChecked正社員() { return this.selectedWorkStyles.includes('正社員'); }
  get isChecked軽作業() { return this.selectedWorkStyles.includes('軽作業'); }
  get isChecked未経験OK() { return this.selectedWorkStyles.includes('未経験OK'); }
  get isChecked扶養内() { return this.selectedWorkStyles.includes('扶養内'); }
  get isCheckedシニア() { return this.selectedWorkStyles.includes('シニア'); }

  get isChecked土() { return this.selectedHolidays.includes('土'); }
  get isChecked日() { return this.selectedHolidays.includes('日'); }
  get isChecked祝() { return this.selectedHolidays.includes('祝'); }

  handleJobDetailNavigation(event) {
    const recordId = event.currentTarget.dataset.recordId;
    if (recordId) {
      window.open(`/joboffer-bu/${recordId}`, '_blank');
    }
  }
  //URLに条件設定//
  connectedCallback() {
    const params = new URLSearchParams(window.location.search);
  
    // クエリパラメータ取得
    const keywordParam = params.get('keyword');
    const minWageParam = params.get('minWage');
    const startTimeParam = params.get('startTime');
    const endTimeParam = params.get('endTime');
    const holidays = params.get('holidays');
    const workStyles = params.get('workStyles');
    const employmentTypes = params.get('employmentTypes');
  
    // 値を設定（日本語対応含む）
    this.keyword = keywordParam ? decodeURIComponent(keywordParam) : '';
    this.minWage = minWageParam ? parseInt(minWageParam, 10) : 900;
    this.startTime = startTimeParam || '';
    this.endTime = endTimeParam || '';
  
    if (holidays) {
      this.selectedHolidays = decodeURIComponent(holidays).split(',');
    }
    if (workStyles) {
      this.selectedWorkStyles = decodeURIComponent(workStyles).split(',');
    }
    if (employmentTypes) {
      this.selectedEmploymentTypes = decodeURIComponent(employmentTypes).split(',');
    }
  
    // 検索実行条件チェック
    const hasAnyCondition =
      this.keyword || holidays || workStyles || employmentTypes ||
      this.minWage > 1000 || this.startTime || this.endTime;
  
    if (hasAnyCondition) {
      this.updateSummaryText();
      this.handleSearch();
    }
  
    // touchイベント抑制（モバイル用）
    document.addEventListener('touchstart', this.preventTouchScrollOnSlider, { passive: false });
  }
  
  
  
}
