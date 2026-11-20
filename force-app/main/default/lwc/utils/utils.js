import { ShowToastEvent } from 'lightning/platformShowToastEvent';

/**
 * Univerzální pomocník pro zobrazení Toast notifikace z libovolné LWC komponenty.
 * @param {LightningElement} cmp - Reference na volající komponentu (this)
 * @param {string} title - Nadpis oznámení
 * @param {string} message - Text zprávy
 * @param {string} variant - 'success' | 'error' | 'warning' | 'info'
 * @param {string} mode - 'dismissable' | 'pester' | 'sticky'
 */
export function showToast(cmp, title, message, variant = 'info', mode = 'dismissable') {
    cmp.dispatchEvent(
        new ShowToastEvent({
            title,
            message,
            variant,
            mode
        })
    );
}

/**
 * Vytáhne čistou textovou zprávu ze strukturovaných chyb Apexu, LDS nebo JS.
 */
export function reduceErrors(errors) {
    if (!Array.isArray(errors)) {
        errors = [errors];
    }

    return errors
        .filter((error) => !!error)
        .map((error) => {
            // 1. UI API / LDS pole chyb
            if (Array.isArray(error.body)) {
                return error.body.map((e) => e.message).join(', ');
            }
            // 2. Standardní Apex AuraHandledException nebo DML chyba
            if (error.body && typeof error.body.message === 'string') {
                return error.body.message;
            }
            // 3. Běžná JavaScript Error instance
            if (typeof error.message === 'string') {
                return error.message;
            }
            return error.statusText || 'Neznámá chyba systému';
        })
        .join(', ');
}