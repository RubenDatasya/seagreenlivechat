package io.agora.sample;

import io.agora.rtm.RtmTokenBuilder;
import io.agora.signal.SignalingToken;

import java.security.NoSuchAlgorithmException;
import java.util.Date;

public class SignalingTokenSample {

    public static void main(String []args) throws NoSuchAlgorithmException{

        String appId = "0089641598304276ab3e6baf141c0258";
        String certificate = "12e9058b7aa64cd6898f2ab446f3e31f";
        String account = "TestAccount";
        //Use the current time plus an available time to guarantee the only time it is obtained
        int expiredTsInSeconds = 1446455471 + (int) (new Date().getTime()/1000l);
        String result = SignalingToken.getToken(appId, certificate, account, expiredTsInSeconds);
        System.out.println(result);
    }

    public String getToken(String userId) throws Exception  {
        String appId = "0089641598304276ab3e6baf141c0258";
        String certificate = "12e9058b7aa64cd6898f2ab446f3e31f";
        String account = "TestAccount";
        //Use the current time plus an available time to guarantee the only time it is obtained
        int expiredTsInSeconds = 1446455471 + (int) (new Date().getTime()/1000l);
        String result = SignalingToken.getToken(appId, certificate, userId, expiredTsInSeconds);
        System.out.println(result);
        return result;
    }
}
