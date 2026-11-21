import { LightningElement, api } from 'lwc';

export default class BikePartItem extends LightningElement {
    // 1. SMĚR DOLŮ (Parent -> Child): Veřejná vlastnost naplněná z rodiče
    @api partName;

    // Lokální stav pouze uvnitř dítěte
    isChecked = false;

    // 2. VEŘEJNÁ METODA (Parent -> Child): Rodič ji může zavolat přímo na instanci dítěte
    @api
    resetCheck() {
        this.isChecked = false;
    }

    handleCheckClick() {
        this.isChecked = !this.isChecked;

        // 3. SMĚR NAHORU (Child -> Parent): Vystřelení události přes hranici Shadow DOMu
        const selectEvent = new CustomEvent('partselected', {
            detail: {
                partName: this.partName,
                isChecked: this.isChecked
            }
        });

        this.dispatchEvent(selectEvent);
    }

    get buttonVariant() {
        return this.isChecked ? 'success' : 'neutral';
    }

    get buttonLabel() {
        return this.isChecked ? 'Hotovo' : 'Zkontrolovat';
    }

}

// Všimni si dvou klíčových věcí:

// Dekorátor @api před partName z ní udělá veřejný vstupní parametr.

// Název události v new CustomEvent('partselected', ...) musí být čistě malými písmeny
// (bez velkých písmen a bez předpony on). Důvodem je specifikace HTML DOMu,
// kde jsou názvy eventů case-insensitive, a LWC kompilátor by camelCase název odmítl.