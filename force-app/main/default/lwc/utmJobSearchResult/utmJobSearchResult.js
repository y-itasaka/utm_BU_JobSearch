import { LightningElement, track } from 'lwc';
import searchJobOffers from '@salesforce/apex/utm_JobSearchResultController.searchJobOffers';

export default class UtmJobSearchResult extends LightningElement {
    @track searchResults = [];
    @track isLoading = false;
    @track keyword = '';

    get isEmpty() {
        return !this.searchResults.length && !this.isLoading;
    }

    handleKeywordChange(event) {
        this.keyword = event.detail.value;
    }

    async handleSearchClick() {
        if (!this.keyword) {
            this.searchResults = [];
            return;
        }

        this.isLoading = true;

        try {
            const results = await searchJobOffers({ keyword: this.keyword });

            this.searchResults = results.map(record => ({
                id: record.Id,
                name: record.Name,
                eyeCatchImage: record.EyeCatchImage__c,
                workLocation: record.WorkLocation__c
            }));

        } catch (error) {
            console.error('検索エラー:', JSON.stringify(error));
        } finally {
            this.isLoading = false;
        }
    }
}