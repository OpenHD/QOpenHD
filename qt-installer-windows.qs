// Emacs mode hint: -*- mode: JavaScript -*-
// https://stackoverflow.com/questions/25105269/silent-install-qt-run-installer-on-ubuntu-server
// https://github.com/wireshark/wireshark/blob/master/tools/qt-installer-windows.qs

var INSTALL_COMPONENTS = [
    "qt.qt5.5125.win32_msvc2017",
    "qt.tools.ifw.31"
];

function Controller() {
    installer.autoRejectMessageBoxes();
    installer.installationFinished.connect(function() {
        gui.clickButton(buttons.NextButton);
    })
}

Controller.prototype.WelcomePageCallback = function() {
    // click delay here because the next button is initially disabled for ~1 second
    gui.clickButton(buttons.NextButton, 3000);
}

Controller.prototype.CredentialsPageCallback = function() {
    gui.clickButton(buttons.NextButton);
}

Controller.prototype.IntroductionPageCallback = function() {
    gui.clickButton(buttons.NextButton);
}

Controller.prototype.DynamicTelemetryPluginFormCallback = function() {
    gui.currentPageWidget().TelemetryPluginForm.statisticGroupBox.disableStatisticRadioButton.setChecked(true);
    gui.clickButton(buttons.NextButton);

    //for(var key in widget.TelemetryPluginForm.statisticGroupBox){
    //    console.log(key);
    //}
}

Controller.prototype.TargetDirectoryPageCallback = function()
{
    // Keep default at "C:\Qt".
    //gui.currentPageWidget().TargetDirectoryLineEdit.setText("E:\\Qt");
    //gui.currentPageWidget().TargetDirectoryLineEdit.setText(installer.value("HomeDir") + "/Qt");
    gui.clickButton(buttons.NextButton);
}

Controller.prototype.ComponentSelectionPageCallback = function() {

    // https://doc-snapshots.qt.io/qtifw-3.1/noninteractive.html
    var page = gui.pageWidgetByObjectName("ComponentSelectionPage");

    var archiveCheckBox = gui.findChild(page, "Archive");
    var latestCheckBox = gui.findChild(page, "Latest releases");
    var fetchButton = gui.findChild(page, "FetchCategoryButton");

    archiveCheckBox.click();
    latestCheckBox.click();
    fetchButton.click();

    var widget = gui.currentPageWidget();

    widget.deselectAll();

    for (var i = 0; i < INSTALL_COMPONENTS.length; i++) {
        widget.selectComponent(INSTALL_COMPONENTS[i]);
    }

    gui.clickButton(buttons.NextButton);
}

Controller.prototype.LicenseAgreementPageCallback = function() {
    gui.currentPageWidget().AcceptLicenseRadioButton.setChecked(true);
    gui.clickButton(buttons.NextButton);
}

Controller.prototype.StartMenuDirectoryPageCallback = function() {
    gui.clickButton(buttons.NextButton);
}

Controller.prototype.ReadyForInstallationPageCallback = function()
{
    gui.clickButton(buttons.NextButton);
}

Controller.prototype.FinishedPageCallback = function() {
var checkBoxForm = gui.currentPageWidget().LaunchQtCreatorCheckBoxForm;
if (checkBoxForm && checkBoxForm.launchQtCreatorCheckBox) {
    checkBoxForm.launchQtCreatorCheckBox.checked = false;
}
    gui.clickButton(buttons.FinishButton);
}