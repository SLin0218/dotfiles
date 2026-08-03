import { Gtk } from "ags/gtk4"
import { type CCProps } from "ags"

type ButtonProps = CCProps<Gtk.Button, Gtk.Button.ConstructorProps>

export enum BarButtonStyle {
  transparent = "transparent",
  primary = "primary",
  primaryContainer = "primary_container",
}

type Props = ButtonProps & {
  buttonStyle?: BarButtonStyle;
  child?: JSX.Element; // when only one child is passed
  cssName?: string;
  onClicked?: () => void;
};

export default ({
  child,
  buttonStyle,
  cssName,
  onClicked,
  cssClasses: _cssClasses,
  valign: _valign,
  ...props
}: Props) => {
  return (
    <button
      cssClasses={[
        'bar__item',
        'bar__button',
        buttonStyle || '',
        cssName || ''
      ].filter(Boolean)}
      onClicked={onClicked}
      valign={Gtk.Align.CENTER}
      {...props}
    >
      {child}
    </button>
  );
};