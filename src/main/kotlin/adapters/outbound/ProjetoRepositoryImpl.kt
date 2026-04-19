package bd2.work.adapters.outbound

import bd2.work.core.domain.Projeto
import bd2.work.core.ports.ProjetoRepository
import jakarta.persistence.Column
import jakarta.persistence.Entity
import jakarta.persistence.GeneratedValue
import jakarta.persistence.GenerationType
import jakarta.persistence.Id
import jakarta.persistence.Table
import org.springframework.data.jpa.repository.JpaRepository
import org.springframework.stereotype.Component
import org.springframework.stereotype.Repository

@Entity
@Table(name = "projetos_estudo")
class ProjetoEntity(
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    val id: Int? = null,

    val nome_projeto: String = "",

    val tecnologia: String = "",

    @Column(name = "data_criacao", updatable = false)
    val data_criacao: java.time.LocalDate? = null
)
@Repository
interface SpringDataProjetoRepository : JpaRepository<ProjetoEntity, Int>

@Component
class ProjetoRepositoryImpl(private val jpaRepository: SpringDataProjetoRepository) : ProjetoRepository {
    override fun buscarTodos(): List<Projeto> =
        jpaRepository.findAll().map { Projeto(it.id, it.nome_projeto, it.tecnologia) }
}