package bd2.work

import org.springframework.boot.autoconfigure.SpringBootApplication
import org.springframework.boot.runApplication

//TIP To <b>Run</b> code, press <shortcut actionId="Run"/> or
// click the <icon src="AllIcons.Actions.Execute"/> icon in the gutter.
@SpringBootApplication
class HospitalAwsApplication

fun main(args: Array<String>) {
    runApplication<HospitalAwsApplication>(*args)
}