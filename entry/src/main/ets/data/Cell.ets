export class Cell {
  public _row: number

  public _col: number

  public  _value: string

  public  _initialValue: string

  public  _correctValue: string

  public _error: boolean = false

  public _locked: boolean = false

  public _noted: boolean = false



  constructor(row: number, col: number, value: string, initialValue: string, correctValue: string, error: boolean, locked: boolean, noted = false) {
    this._row = row;
    this._col = col;
    this._value = value;
    this._initialValue = initialValue;
    this._correctValue = correctValue;
    this._error = error;
    this._locked = locked;
    this._noted = noted
  }
}