import { createPoll } from "ags/time"
import { Gtk } from "ags/gtk4"
import { createState } from "ags"
import { Solar } from "lunar-javascript";
import GLib from "gi://GLib"

function getLunarText(date: GLib.DateTime) {
  const year = date.get_year();
  const month = date.get_month();
  const day = date.get_day_of_month();
  const solar = Solar.fromYmd(year, month, day);
  const lunar = solar.getLunar();
  const festival = lunar.getFestivals()?.length > 0 ? lunar.getFestivals()[0] : "";
  const yearGanZhi = lunar.getYearInGanZhi()
  const yearShengXiao = lunar.getYearShengXiao()
  const monthInChinese = lunar.getMonthInChinese()
  const dayInChinese = lunar.getDayInChinese()
  const jieQi = lunar.getJieQi();
  return `${yearGanZhi}${yearShengXiao}年    ${monthInChinese}月${dayInChinese}日    ${jieQi}    ${festival}`;
}

export default () => {
  const time = createPoll("", 1000, () =>
    GLib.DateTime.new_now_local().format("%a %b %d %H:%M:%S") || ""
  )
  const [lunarText, setLunarText] = createState(getLunarText(GLib.DateTime.new_now_local()));
  let calendar: Gtk.Calendar;

  return (
    <menubutton label={time} direction={Gtk.ArrowType.NONE}>
      <popover cssClasses={["calendar-popover"]}
        $={(self) => {
          self.connect("notify::visible", () => {
            if (!self.visible) {
              calendar.select_day(GLib.DateTime.new_now_local());
            }
          })
        }}
      >
        <box
          orientation={Gtk.Orientation.VERTICAL}
        >
          <Gtk.Calendar
            $={(self) => { calendar = self }}
            onDaySelected={(self) => {
              setLunarText(getLunarText(self.get_date()));
            }}
          >
            <box cssClasses={["lunar-box"]}>
              <label label={lunarText}></label>
            </box>
          </Gtk.Calendar>

        </box>

      </popover>
    </menubutton>
  );
}