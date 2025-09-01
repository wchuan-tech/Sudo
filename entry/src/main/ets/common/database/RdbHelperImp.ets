import { relationalStore } from '@kit.ArkData';
import tableHelper from './TableHelper';
import { RdbHelper } from './RdbHelper';
import ColumnInfo from '../../viewmodel/ColumnInfo';
import { LogUtil } from '../../utils/LogUtil';
import { window } from '@kit.ArkUI';
import { GlobalContext } from '../constants/GlobalContext'; // 假设已创建

const DATABASE_NAME = 'Rdb.db';
// 1. 定义数据库常量
const DB_VERSION = 1; // 您的数据库版本号

export class RdbHelperImp implements RdbHelper {

  private mDatabaseName: string;
  // 信息实例 即数据库实例话
  private rdbStore: relationalStore.RdbStore | null= null;
  private isInitialized: boolean = false;

  // 1. 单例模式
  private static instance: RdbHelperImp | null = null;


  constructor(databaseName: string) {
    this.mDatabaseName = databaseName;
  }

  public static getInstance(dbName: string): RdbHelperImp {
    // 使用类名 RdbHelperImp 来访问静态属性 instance
    if (RdbHelperImp.instance === null) {
      RdbHelperImp.instance = new RdbHelperImp(dbName);
    }
    return RdbHelperImp.instance;
  }


  getDbName(): string {
    return this.mDatabaseName;
  }

  async getRdb(context: Context): Promise<RdbHelper> {
    // 1. 调用权威的 initialize 方法，并等待它完成。
    //    这确保了数据库连接、建表、版本管理等所有步骤都已执行。
    await this.initialize();
    // 2. 初始化完成后，this 对象已经是完全准备好的状态，直接返回它。
    return this;
  }

  public  initialize(): Promise<void> {

    if (this.isInitialized) {
      LogUtil.info('Database is already initialized.');
      return Promise.resolve();
    }

    return new Promise((resolve, reject) => {
      try {
        const context = GlobalContext.getContext();
        const storeConfig: relationalStore.StoreConfig = {
          name: DATABASE_NAME,
          securityLevel: relationalStore.SecurityLevel.S1
        } as relationalStore.StoreConfig;

        relationalStore.getRdbStore(context, storeConfig, (err, store) => {
          if (err) {
            LogUtil.error(`Failed to get RdbStore. Code:${err.code}, message:${err.message}`);
            reject(err); // 初始化失败，Promise被拒绝
            return;
          }

          LogUtil.info('Succeeded in getting RdbStore.');
          this.rdbStore = store;

          // 4. 执行版本管理和表结构更新
          try {
            // 升级数据库
            this.onUpgrade(store);
            this.isInitialized = true;
            LogUtil.info('Database initialization and version management completed.');
            resolve(); // 初始化成功，Promise被解决
          } catch (upgradeError) {
            LogUtil.error('Failed during database upgrade process.', upgradeError);
            reject(upgradeError);
          }
        });
      } catch (error) { // 这个 catch 只捕获 getContext 的同步错误
        reject(error);
      }
    });
  }


  private getInitializedRdbStore(): relationalStore.RdbStore {
    if (!this.isInitialized || this.rdbStore === null) {
      throw new Error("RdbHelper has not been initialized. Call initialize() first.");
    }
    return this.rdbStore;
  }

  onUpgrade(store: relationalStore.RdbStore) {
    let currentVersion = store.version;
    LogUtil.info(`Current DB version: ${currentVersion}, Target DB version: ${DB_VERSION}`);

    // 创建 game_records 表
    const SQL_CREATE_GAME_RECORDS_TABLE = `
    CREATE TABLE IF NOT EXISTS game_records (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      difficulty TEXT NOT NULL UNIQUE,
      best_time INTEGER NOT NULL
    )
  `;

    // 从当前版本开始，逐级升级到目标版本
    if (currentVersion < 1) { // 对应文档中的 version === 0
        LogUtil.info('Upgrading from version 0 to 1: Creating initial tables.');
        store.executeSql(SQL_CREATE_GAME_RECORDS_TABLE);
    }

    if (currentVersion < 2) {
        LogUtil.info('Upgrading from version 1 to 2: Adding column "salary".');
        store.executeSql('ALTER TABLE game_records ADD COLUMN best_time INTEGER NOT NULL DEFAULT 0');
    }

    if (currentVersion < 3) {
        LogUtil.info('Upgrading from version 2 to 3: Adding column "address".');
        store.executeSql('CREATE UNIQUE INDEX IF NOT EXISTS idx_difficulty_unique ON game_records (difficulty)');
    }

    // 所有升级步骤完成后，将数据库版本设置为最终的目标版本
    store.version = DB_VERSION;
    LogUtil.info(`Database successfully upgraded to version ${store.version}`);
  }

  executeSql(sql: string): Promise<void> {
    LogUtil.info(`executeSql sql试一下 : ${sql}`);
    return this.getInitializedRdbStore().executeSql(sql);
  }

  createTable(tableName: string, columns: Array<ColumnInfo>): Promise<void> {
    LogUtil.info(`createTable tableName : ${tableName}, columns : ${JSON.stringify(columns)}`);
    let createTableSql = tableHelper.createTableSql(tableName, columns);
    LogUtil.info(`createTable tableName3164 : ${createTableSql}`);
    return this.executeSql(createTableSql);
  }

  deleteTable(tableName: string): Promise<void> {
    LogUtil.info(`deleteTable tableName : ${tableName}`);
    let deleteTableSql = tableHelper.deleteTableSql(tableName);
    return this.executeSql(deleteTableSql);
  }

  addTableColumn(tableName: string, column: ColumnInfo): Promise<void> {
    LogUtil.info(`addTableColumn tableName : ${tableName}, column : ${JSON.stringify(column)}`);
    let addTableColumnSql = tableHelper.addTableColumnSql(tableName, column);
    return this.executeSql(addTableColumnSql);
  }

  async insert(tableName: string, values: relationalStore.ValuesBucket | Array<relationalStore.ValuesBucket>): Promise<number> {
    const store = this.getInitializedRdbStore();

    if (!values) {
      throw new Error("Values to insert cannot be undefined.");
    }


    if (Array.isArray(values)) {
      if (values.length === 0) {
        return 0; // 空数组直接返回
      }

      let insertedCount = 0;
      // 3. 使用 try...catch 包裹事务操作
      try {
        store.beginTransaction();

        // 4. 使用简洁的 for...of 循环代替 saveArray/saveData
        for (const value of values) {
          await store.insert(tableName, value);
          insertedCount++;
        }

        // 5. 成功时提交
        store.commit();
        return insertedCount;

      } catch (err) {
        LogUtil.error(`Bulk insert failed, rolling back. Error: ${JSON.stringify(err)}`);
        // 6. 失败时回滚
        store.rollBack();
        // 7. 向上抛出错误
        if (err instanceof Error) {
          // 如果 err 本身就是一个 Error 对象，直接重新抛出它，
          // 这样可以保留完整的错误信息和堆栈跟踪
          throw err;
        } else {
          // 如果 err 是其他类型（比如一个字符串），则创建一个新的 Error 对象
          throw new Error(`An unexpected, non-Error type was thrown: ${JSON.stringify(err)}`);
        }
      }
    } else {
      // 8. 处理单条插入，无需事务
      return store.insert(tableName, values);
    }
  }






  // private saveArray(tableName: string, values: Array<relationalStore.ValuesBucket>): Promise<number> {
  //   return new Promise<number>((success, error) => {
  //     if (!values || values.length === 0) {
  //       error(0);
  //       return;
  //     }
  //     let index = 0
  //     let callback = (data: number, err: Error) => {
  //       if (err) {
  //         LogUtil.info(`saveArray failed, err : ${err}`);
  //         error(err);
  //         return;
  //       }
  //       if (data) {
  //         if (index < values.length - 1) {
  //           this.saveData(tableName, values, ++index, callback);
  //         } else {
  //           success(data);
  //         }
  //       }
  //     }
  //     this.saveData(tableName, values, index, callback);
  //   })
  // }
  //
  // private saveData(tableName: string, values: Array<relationalStore.ValuesBucket>, index: number, callback: Function): void {
  //   LogUtil.info(`saveData tableName : ${tableName}, index : ${JSON.stringify(index)}`);
  //
  //   this.getInitializedRdbStore().insert(tableName, values[index]).then((data: number) => {
  //     LogUtil.info(`saveData success id : ${data}`);
  //     callback(data);
  //   }).catch((err: Error) => {
  //     LogUtil.error(`saveData failed, err : ${err}`);
  //     callback(err);
  //   })
  // }

  update(values: relationalStore.ValuesBucket, rdbPredicates: relationalStore.RdbPredicates): Promise<number> {
    LogUtil.debug("RdbHelperImp update")
    return this.getInitializedRdbStore().update(values, rdbPredicates);
  }

  query(rdbPredicates: relationalStore.RdbPredicates, columns?: Array<string>): Promise<relationalStore.ResultSet> {
    LogUtil.info(`query rdbPredicates : ${JSON.stringify(rdbPredicates)}`);
    return this.getInitializedRdbStore().query(rdbPredicates, columns);
  }

  queryAll(tableName: string): Promise<relationalStore.ResultSet> {
    LogUtil.info(`queryAllSize tableName : ${tableName}`);
    return this.getInitializedRdbStore().querySql(`select * from ${tableName}`);
  }

  queryBySql(sql: string, bindArgs?: Array<relationalStore.ValueType>): Promise<relationalStore.ResultSet> {
    LogUtil.info(`queryBySql sql : ${sql}`);
    return this.getInitializedRdbStore().querySql(sql, bindArgs);
  }

  delete(rdbPredicates: relationalStore.RdbPredicates): Promise<number> {
    LogUtil.info(`delete rdbPredicates : ${JSON.stringify(rdbPredicates)}`);
    return this.getInitializedRdbStore().delete(rdbPredicates);
  }
}

export const rdbHelper = RdbHelperImp.getInstance(DATABASE_NAME);