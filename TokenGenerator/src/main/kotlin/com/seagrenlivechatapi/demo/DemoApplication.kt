package com.seagrenlivechatapi.demo

import io.agora.sample.RtmTokenBuilderSample
import org.springframework.boot.autoconfigure.SpringBootApplication
import org.springframework.boot.runApplication
import org.springframework.http.HttpStatus
import org.springframework.http.ResponseEntity
import org.springframework.web.bind.annotation.GetMapping
import org.springframework.web.bind.annotation.RequestMapping
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

	@GetMapping("tokens")
	fun getStatus(): ResponseEntity<Token> {
		val sampler = RtmTokenBuilderSample()
		return ResponseEntity(Token(value =  sampler.token), HttpStatus.OK)
	}

}