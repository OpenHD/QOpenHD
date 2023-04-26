package org.openhd;

import android.app.Activity;
import android.app.AlertDialog;
import android.content.ActivityNotFoundException;
import android.content.ComponentName;
import android.content.Context;
import android.content.DialogInterface;
import android.content.Intent;
import android.content.IntentFilter;
import android.net.wifi.SupplicantState;
import android.net.wifi.WifiInfo;
import android.net.wifi.WifiManager;
import android.os.Bundle;
import android.os.Looper;
import android.util.Log;
import android.widget.Toast;

import java.net.Inet4Address;
import java.net.InetAddress;
import java.net.NetworkInterface;
import java.util.Enumeration;

//Created for FPV-VR by Constantin
//Helps with USB status / start USB tethering

public final class IsConnected {

    public static Context m_stored_context=null;

    public enum USB_CONNECTION{
        NOTHING,DATA,TETHERING
    }

    private static boolean checkWifiConnectedToNetwork(final Context context,final String networkName){
        WifiManager wifiManager = (WifiManager) context.getApplicationContext().getSystemService(Context.WIFI_SERVICE);
        WifiInfo wifiInfo;
        if(wifiManager==null){
            return false;
        }
        wifiInfo = wifiManager.getConnectionInfo();
        if (wifiInfo.getSupplicantState() == SupplicantState.COMPLETED ) {
            String ssid = wifiInfo.getSSID();
            return ssid.equals(networkName);
        }
        return false;
        //System.out.println(wifiInfo.getSupplicantState().toString());
    }

    public static boolean checkWifiConnectedOpenHD(final Context context){
        return checkWifiConnectedToNetwork(context,"\"Open.HD\"");
    }

    public static boolean checkWifiConnectedTest(final Context context){
        return checkWifiConnectedToNetwork(context,"\"TestAero\"");
    }

    public static boolean checkWifiConnectedEZWB(final Context context){
        return checkWifiConnectedToNetwork(context,"\"EZ-WifiBroadcast\"");
    }


    public static USB_CONNECTION getUSBStatus(Context context){
        final Intent intent = context.registerReceiver(null, new IntentFilter("android.hardware.usb.action.USB_STATE"));
        if(intent!=null){
            final Bundle extras=intent.getExtras();
            if(extras!=null){
                final boolean connected=extras.getBoolean("connected",false);
                final boolean tetheringActive=extras.getBoolean("rndis",false);
                if(tetheringActive){
                    return USB_CONNECTION.TETHERING;
                }
                if(connected){
                    return USB_CONNECTION.DATA;
                }
            }
        }
        //UsbManager manager=(UsbManager)context.getSystemService(Context.USB_SERVICE);
        //manager.getClass().getDeclaredMethods().
        return USB_CONNECTION.NOTHING;
    }


    public static String getUSBTetheringLoopbackAddress(){
        try{
            for(Enumeration<NetworkInterface> en = NetworkInterface.getNetworkInterfaces(); en.hasMoreElements();){
                final NetworkInterface intf=en.nextElement();
                //System.out.println("Intf:"+intf.getName());
                if(intf.getName().contains("rndis")){
                    final Enumeration<InetAddress> inetAdresses=intf.getInetAddresses();
                    while (inetAdresses.hasMoreElements()){
                        final InetAddress inetAddress=inetAdresses.nextElement();
                        System.out.println(inetAddress.toString());
                        //if(inetAddress.isLoopbackAddress()){
                            return inetAddress.toString().replace("/","");
                        //}
                    }
                }
            }
        }catch(Exception e){e.printStackTrace();}
        return null;
    }

    public static int getLastNumberOfIP(final String ip){
        String[] parts = ip.split(".");
        assert (parts.length==4);
        return Integer.parseInt(parts[3]);
    }

    public static void openUSBTetherSettings(final Context c){
        try{
            final Intent intent = new Intent(Intent.ACTION_MAIN, null);
            intent.addCategory(Intent.CATEGORY_LAUNCHER);
            final ComponentName cn = new ComponentName("com.android.settings", "com.android.settings.TetherSettings");
            intent.setComponent(cn);
            intent.setFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
            c.startActivity(intent);
        }catch (ActivityNotFoundException e){
            e.printStackTrace();
            Toast.makeText(c,"USB Tethering is not available on this Phone",Toast.LENGTH_LONG).show();
        }
    }

    public static void makeAlertDialogOpenTetherSettings(final Context c){
        Log.d("TEST","makeAlertDialogOpenTetherSettings");
        new AlertDialog.Builder(c).setMessage("enable 'USB tethering' (not wifi,but usb hotspot)")
                .setPositiveButton("Okay", new DialogInterface.OnClickListener() {
                    @Override
                    public void onClick(DialogInterface dialog, int which) {
                        openUSBTetherSettings(c);
                    }
                }).show();
    }
    // For QT
    public static void makeAlertDialogOpenTetherSettings2(){
        Log.d("TEST","makeAlertDialogOpenTetherSettings2");
        if(m_stored_context!=null){
            ((Activity)m_stored_context).runOnUiThread(new Runnable() {
                @Override
                public void run() {
                    makeAlertDialogOpenTetherSettings(m_stored_context);
                }
            });
        }
    }


    // X
    //get all Inet4Addresses that are
    //either wifi or wifi hotspot or usb tethering
    public static String getActiveInetAddresses(){
        StringBuilder s= new StringBuilder();
        try{
            final Enumeration<NetworkInterface> networkInterfacesEnumeration=NetworkInterface.getNetworkInterfaces();
            while (networkInterfacesEnumeration.hasMoreElements()){
                final NetworkInterface networkInterface=networkInterfacesEnumeration.nextElement();
                if(!networkInterface.isUp() || networkInterface.getName().contains("dummy0") || networkInterface.isLoopback()){
                    continue;
                }
                final Enumeration<InetAddress> inetAddressesEnumeration=networkInterface.getInetAddresses();
                while (inetAddressesEnumeration.hasMoreElements()){
                    InetAddress inetAddress=inetAddressesEnumeration.nextElement();
                    if(inetAddress instanceof Inet4Address){
                        s.append("Interface ").append(networkInterface.getName()).append(": ").append(inetAddress.getHostAddress()).append("\n");
                    }
                }
            }
            return s.toString();
        }catch(Exception e){e.printStackTrace();}
        return "";
    }

}
