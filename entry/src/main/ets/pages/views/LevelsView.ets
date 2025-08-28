import { List } from "@kit.ArkTS"
import { LevelInfo } from "../../data/Levelnfo"

@Component
export struct LevelsView {

  @Link
  levelInfos: Array<LevelInfo>

  build() {
    RelativeContainer() {
      GridRow({
        columns: 5,
        gutter: { y: 20 },
        direction: GridRowDirection.Row
      }) {
        ForEach(this.levelInfos, (item: LevelInfo) => {
          GridCol() {
            Stack() {
              Image($r('app.media.star'))
                .width('100%')
              Image($r('app.media.lock'))
                .width('100%')
            }
          }

        })
      }

    }
  }
}