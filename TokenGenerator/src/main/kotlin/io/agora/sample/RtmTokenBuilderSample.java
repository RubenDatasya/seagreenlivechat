package io.agora.sample;

import io.agora.rtm.RtmTokenBuilder;
import io.agora.rtm.RtmTokenBuilder.Role;

import java.util.Date;

public class RtmTokenBuilderSample {
    String appId = "0089641598304276ab3e6baf141c0258";
    String certificate = "12e9058b7aa64cd6898f2ab446f3e31f";
    private static String userId = "2882341273";
    private static int expireTimestamp = 0;

//    public static void main(String[] args) throws Exception {
//    	RtmTokenBuilder token = new RtmTokenBuilder();
//        String result = token.buildToken(appId, appCertificate, userId, Role.Rtm_User, expireTimestamp);
//        System.out.println(result);
//    }

     public String getToken() throws Exception  {
        RtmTokenBuilder token = new RtmTokenBuilder();
        String result = token.buildToken(appId, certificate, userId, Role.Rtm_User, expireTimestamp);
        System.out.println(result);
        return result;
    }


    public String getToken(String userId) throws Exception  {
        RtmTokenBuilder token = new RtmTokenBuilder();
        int expiredTsInSeconds = 1446455471 + (int) (new Date().getTime()/1000l);
        String result = token.buildToken(appId, certificate, userId, Role.Rtm_User, expiredTsInSeconds);
        System.out.println(result);
        return result;
    }
}
