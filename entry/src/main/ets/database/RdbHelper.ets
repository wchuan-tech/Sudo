import { relationalStore } from '@kit.ArkData';
import ColumnInfo from '../data/ColumnInfo';

export interface RdbHelper {

  initialize(): Promise<void>;


  getDbName(): string;


  getRdb(context: Context): Promise<RdbHelper>;


  executeSql(sql: string): Promise<void>;


  createTable(tableName: string, columns: Array<ColumnInfo>): Promise<void>;


  deleteTable(tableName: string): Promise<void>;


  addTableColumn(tableName: string, column: ColumnInfo): Promise<void>;


  insert(tableName: string, values: relationalStore.ValuesBucket | Array<relationalStore.ValuesBucket>): Promise<number>;


  update(values: relationalStore.ValuesBucket, rdbPredicates: relationalStore.RdbPredicates): Promise<number>;


  query(rdbPredicates: relationalStore.RdbPredicates, columns?: Array<string>): Promise<relationalStore.ResultSet>;


  queryAll(tableName: string): Promise<relationalStore.ResultSet>;


  queryBySql(sql: string, bindArgs?: Array<relationalStore.ValueType>): Promise<relationalStore.ResultSet>;


  delete(rdbPredicates: relationalStore.RdbPredicates): Promise<number>;
}