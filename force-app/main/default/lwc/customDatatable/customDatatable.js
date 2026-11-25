import LightningDatatable from 'lightning/datatable';
import picklistTemplate from './picklistTemplate.html';
import picklistEditTemplate from './picklistEditTemplate.html';

export default class CustomDatatable extends LightningDatatable {
    static customTypes = {
        picklist: {
            template: picklistTemplate,
            editTemplate: picklistEditTemplate,
            standardCellLayout: true,
            typeAttributes: ['label', 'placeholder', 'options', 'value', 'context']
        }
    };
}

// Všimni si, že komponenta nemá vlastní customDatatable.html
// ten výchozí soubor můžeš ze složky customDatatable smazat,
// protože HTML dědí přímo z LightningDatatable.