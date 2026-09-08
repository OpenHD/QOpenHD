#include <QApplication>
#include <QSettings>
#include <iostream>
#include "telemetry/settings/mavlinksettingsmodel.h"

int main(int argc, char** argv) {
    QCoreApplication app(argc, argv);
    app.setOrganizationName("OpenHDModelRegression");
    app.setApplicationName("HiddenParametersTest");
    QSettings().setValue("dev_show_whitelisted_params", false);
    MavlinkSettingsModel model(100,191);
    model.addData({"TX_PWR_LVL", int32_t(40)});
    if (model.rowCount()!=0 || !model.param_int_exists("TX_PWR_LVL") || model.get_cached_int("TX_PWR_LVL")!=40) return 1;
    model.updateData(std::nullopt, {"TX_PWR_LVL", int32_t(60)});
    if(model.get_cached_int("TX_PWR_LVL")!=60) return 2;
    model.ui_thread_replace_param_set({{{"TX_PWR_LVL",80,0},{"WB_PIT_MODE",1,0},{"TEST_VISIBLE",3,0}}});
    if(model.get_cached_int("TX_PWR_LVL")!=80 || model.get_cached_int("WB_PIT_MODE")!=1 || model.rowCount()!=1) return 3;
    model.ui_thread_replace_param_set({});
    if(model.param_int_exists("TX_PWR_LVL") || model.param_int_exists("WB_PIT_MODE")) return 4;
    std::cout << "Hidden Link parameters: fetch, lookup, update and refetch PASS\n";
    return 0;
}
