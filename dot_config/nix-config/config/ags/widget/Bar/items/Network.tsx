import { createBinding, createState, With } from "ags"
import Network from "gi://AstalNetwork";

export default () => {
  const net = Network.get_default();
  return (
    <button>
      <With value={createBinding(net, "primary")} >
        {primary => {
          switch (primary) {
            case Network.Primary.WIRED:
              return <image
                iconName={createBinding(net.wired, "icon_name").as(String)}
                tooltipText={createBinding(net.wired, "device").as(String)}
              />
            case Network.Primary.WIFI:
              return <image
                iconName={createBinding(net.wifi, "icon_name").as(String)}
                tooltipText={createBinding(net.wifi, "ssid").as(String)}
              />
            default:
              return <image iconName={"network-idle-symbolic"} tooltipText={"no connected"} />
          }
        }}
      </With>
    </button>
  );
}