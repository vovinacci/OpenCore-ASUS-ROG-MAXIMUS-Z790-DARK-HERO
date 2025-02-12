# Known issues

- **Open**
  - [ ] Motherboard-based Intel Wi-Fi 6 AX201 card is not supported on macOS Sequoia.
    See [OpenIntelWireless/itlwm#983](https://github.com/OpenIntelWireless/itlwm/issues/983) and
    [OpenIntelWireless/itlwm#1009)](https://github.com/OpenIntelWireless/itlwm/issues/1009) for more details.

    **Workaround**: (10-Feb-2025) Use LAN connection via
    [BrosTrend AC1200 WiFi to Ethernet Adapter](https://www.amazon.com/BrosTrend-600Mbps-Adapter-Wireless-WNA016/dp/B0118SPFCK).

- **Resolved**
  - [x] Motherboard-based Bluetooth doesn't work.

    **Solution**: (10-Feb-2025) Use
    [fenvi FV-HB1200 802.11a/b/g/n/ac PCIe x1 Wi-Fi Adapter](https://pcpartpicker.com/product/bBFmP6/fenvi-fv-hb1200-80211abgnac-pcie-x1-wi-fi-adapter-fv-hb1200)
    as a Bluetooth module only.

    **Note**: Wi-Fi will not work as `IO80211FamilyLegacy` support was removed in Sonoma, which drops support for **BCM94360** based cards.
