package com.seagrenlivechatapi.demo

import io.agora.sample.RtmTokenBuilderSample
import io.agora.sample.SignalingTokenSample
import org.springframework.boot.autoconfigure.SpringBootApplication
import org.springframework.boot.runApplication
import org.springframework.http.HttpStatus
import org.springframework.http.ResponseEntity
import org.springframework.web.bind.annotation.GetMapping
import org.springframework.web.bind.annotation.RequestMapping
import org.springframework.web.bind.annotation.RequestParam
import org.springframework.web.bind.annotation.RestController

@SpringBootApplication
class DemoApplication

fun main(args: Array<String>) {
	runApplication<DemoApplication>(*args)
}

data class Token(var value:String)
@RestController
@RequestMapping("/")
class AgoraTokenController {

	@GetMapping("chatToken")
	fun getRtmToken(@RequestParam userid: String): ResponseEntity<Token> {
		val sampler = RtmTokenBuilderSample()
		val rtm = sampler.getToken(userid)
		return ResponseEntity(Token(value = rtm), HttpStatus.OK)
	}
	@GetMapping("messagingToken")
	fun getSignalingToken(@RequestParam userid: String): ResponseEntity<Token> {
		val sampler = SignalingTokenSample()
		val token =  sampler.getToken(userid)
		return ResponseEntity(Token(value =  token), HttpStatus.OK)
	}

}