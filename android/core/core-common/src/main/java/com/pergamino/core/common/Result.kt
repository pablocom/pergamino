package com.pergamino.core.common

/**
 * A discriminated union that encapsulates a successful outcome with a value of type [T]
 * or a failure with an error of type [E].
 *
 * This is a functional approach to error handling that makes errors explicit in the type system,
 * forcing callers to handle both success and failure cases.
 */
sealed class Result<out T, out E> {
    data class Success<T>(val value: T) : Result<T, Nothing>()
    data class Failure<E>(val error: E) : Result<Nothing, E>()

    val isSuccess: Boolean get() = this is Success
    val isFailure: Boolean get() = this is Failure

    fun getOrNull(): T? = when (this) {
        is Success -> value
        is Failure -> null
    }

    fun errorOrNull(): E? = when (this) {
        is Success -> null
        is Failure -> error
    }

    fun getOrThrow(): T = when (this) {
        is Success -> value
        is Failure -> throw IllegalStateException("Result is Failure: $error")
    }

    inline fun getOrElse(defaultValue: (E) -> @UnsafeVariance T): T = when (this) {
        is Success -> value
        is Failure -> defaultValue(error)
    }

    inline fun <R> map(transform: (T) -> R): Result<R, E> = when (this) {
        is Success -> Success(transform(value))
        is Failure -> this
    }

    inline fun <R> mapError(transform: (E) -> R): Result<T, R> = when (this) {
        is Success -> this
        is Failure -> Failure(transform(error))
    }

    inline fun <R> flatMap(transform: (T) -> Result<R, @UnsafeVariance E>): Result<R, E> = when (this) {
        is Success -> transform(value)
        is Failure -> this
    }

    inline fun onSuccess(action: (T) -> Unit): Result<T, E> {
        if (this is Success) action(value)
        return this
    }

    inline fun onFailure(action: (E) -> Unit): Result<T, E> {
        if (this is Failure) action(error)
        return this
    }

    inline fun <R> fold(onSuccess: (T) -> R, onFailure: (E) -> R): R = when (this) {
        is Success -> onSuccess(value)
        is Failure -> onFailure(error)
    }

    companion object {
        fun <T> success(value: T): Result<T, Nothing> = Success(value)

        fun <E> failure(error: E): Result<Nothing, E> = Failure(error)

        inline fun <T> runCatching(block: () -> T): Result<T, Throwable> {
            return try {
                Success(block())
            } catch (e: Throwable) {
                Failure(e)
            }
        }
    }
}
