package bd2.work.core.ports

import bd2.work.core.domain.Projeto

interface ProjetoService {
    fun listarTodos(): List<Projeto>
}