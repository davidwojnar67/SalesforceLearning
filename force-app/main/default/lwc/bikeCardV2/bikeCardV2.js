import { LightningElement, api } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class BikeCardV2 extends LightningElement {
    @api recordId;

    handleSuccess() {
        this.dispatchEvent(
            new ShowToastEvent({
                title: 'Uloženo',
                message: 'Data byla uložena přes LDS!',
                variant: 'success'
            })
        );
    }
}