package bd2.work.core.domain

import java.time.LocalDate

data class Projeto(
    val id: Int? = null,
    val nomeProjeto: String,
    val tecnologia: String?,
    val dataCriacao: LocalDate? = LocalDate.now()
)