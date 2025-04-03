import { LightningElement, track } from 'lwc';
import utm_searchJobs from '@salesforce/apex/utm_AdvancedSearchController.utm_searchJobs';

export default class UtmJobSearch extends LightningElement {
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
    if (e.target && e.target.type === 'range') {
      e.preventDefault();
    }
  }

  toggleFilters() {
    this.showFilters = !this.showFilters;
  }

  handleSearchAndClose() {
    this.updateSummaryText(); // ✅ モーダル閉じ時にも更新
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

  handleClearAll() {
    this.keyword = '';
    this.selectedHolidays = [];
    this.minWage = 900;
    this.startTime = '';
    this.endTime = '';
    this.selectedEmploymentTypes = [];
    this.selectedWorkStyles = [];
    this.isNoResults = false;
    this.updateSummaryText(); // ✅ リセット後も更新
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
    // employmentTypesは summaryText に含まれないので updateSummaryText() は不要
  }

  get formattedMinWage() {
    return this.minWage.toLocaleString();
  }

  handleSearch() {
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
          return {
            ...job,
            formattedSalaryMin: salaryMin ? Number(salaryMin).toLocaleString() : '',
            formattedSalaryMax: salaryMax ? Number(salaryMax).toLocaleString() : ''
          };
        });
        this.isNoResults = this.results.length === 0;
      })
      .catch(error => {
        console.error('検索エラー:', error);
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

  // ✅ チェックボックス状態
  get isChecked正社員() { return this.selectedWorkStyles.includes('正社員'); }
  get isChecked軽作業() { return this.selectedWorkStyles.includes('軽作業'); }
  get isChecked未経験OK() { return this.selectedWorkStyles.includes('未経験OK'); }
  get isChecked扶養内() { return this.selectedWorkStyles.includes('扶養内'); }
  get isCheckedシニア() { return this.selectedWorkStyles.includes('シニア'); }

  get isChecked土() { return this.selectedHolidays.includes('土'); }
  get isChecked日() { return this.selectedHolidays.includes('日'); }
  get isChecked祝() { return this.selectedHolidays.includes('祝'); }




  //詳細ページ遷移
  handleJobDetailNavigation(event) {
    const recordId = event.currentTarget.dataset.recordId;
    if (recordId) {
      window.open(`/job-offer/${recordId}`, '_blank');

    }
  }
  
}
