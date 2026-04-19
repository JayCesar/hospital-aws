package bd2.work.adapters.inbound

import bd2.work.core.ports.ProjetoService
import org.springframework.web.bind.annotation.GetMapping
import org.springframework.web.bind.annotation.RequestMapping
import org.springframework.web.bind.annotation.RestController

@RestController
@RequestMapping("/projetos")
class ProjetoController(private val service: ProjetoService) {
    @GetMapping
    fun getProjetos() = service.listarTodos()
}