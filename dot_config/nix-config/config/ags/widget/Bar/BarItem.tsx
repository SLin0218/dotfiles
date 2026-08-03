import { Gtk } from "ags/gtk4";
import { type CCProps } from "ags"

type BoxProps = CCProps<Gtk.Box, Gtk.Box.ConstructorProps>

export enum BarItemStyle {
  transparent = "transparent",
  primary = "primary",
  primaryContainer = "primary_container",
}

type Props = BoxProps & {
  itemStyle?: BarItemStyle;
  child?: JSX.Element;
  cssName?: string;
  cssClasses?: string[];
};

export default ({
  child,
  itemStyle,
  cssName,
  cssClasses: _cssClasses,
  valign: _valign,
  ...props
}: Props) => {
  return (
    <box
      cssClasses={[
        "baritem",
        itemStyle || "",
        cssName || "",
        ...(_cssClasses || []),
      ].filter(Boolean)}
      valign={_valign || Gtk.Align.CENTER}
      {...props}
    >
      {child}
    </box>
  );
};