package bd2.work.application

import bd2.work.core.domain.Projeto
import bd2.work.core.ports.ProjetoRepository
import bd2.work.core.ports.ProjetoService
import org.springframework.stereotype.Service

@Service // Se não quiser usar @Service aqui, use a BeanConfiguration que te passei antes
class ProjetoServiceImpl(private val repository: ProjetoRepository) : ProjetoService {
    override fun listarTodos(): List<Projeto> = repository.buscarTodos()
}