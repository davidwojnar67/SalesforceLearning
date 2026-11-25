// 06_Salesforce/Teorie/12_LWC Lifecycle Hooks a Error Boundary (errorCallback)
import { LightningElement } from 'lwc';

export default class ErrorBoundary extends LightningElement {
    errorMessage;
    errorStack;

    constructor() {
        super();
        console.log('[ErrorBoundary] 1. constructor');
    }

    connectedCallback() {
        console.log('[ErrorBoundary] 2. connectedCallback');
    }

    renderedCallback() {
        console.log('[ErrorBoundary] 3. renderedCallback');
    }

    disconnectedCallback() {
        console.log('[ErrorBoundary] 4. disconnectedCallback')
    }

    errorCallback(error, stack) {
        console.error('[ErrorBoundary] Zachycena chyba potomka:', error);
        this.errorMessage = error?.message || String(error);
        this.errorStack = stack;
    }

    get hasError() {
        return Boolean(this.errorMessage);
    }

    handleReset() {
        this.errorMessage = undefined;
        this.errorStack = undefined;
    }
}