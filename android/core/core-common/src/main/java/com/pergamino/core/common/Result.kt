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

    /**
     * Returns the encapsulated value if this instance represents [Success] or null otherwise.
     */
    fun getOrNull(): T? = when (this) {
        is Success -> value
        is Failure -> null
    }

    /**
     * Returns the encapsulated error if this instance represents [Failure] or null otherwise.
     */
    fun errorOrNull(): E? = when (this) {
        is Success -> null
        is Failure -> error
    }

    /**
     * Returns the encapsulated value if this instance represents [Success] or throws an exception otherwise.
     */
    fun getOrThrow(): T = when (this) {
        is Success -> value
        is Failure -> throw IllegalStateException("Result is Failure: $error")
    }

    /**
     * Returns the encapsulated value if this instance represents [Success]
     * or the result of [defaultValue] function otherwise.
     */
    inline fun getOrElse(defaultValue: (E) -> @UnsafeVariance T): T = when (this) {
        is Success -> value
        is Failure -> defaultValue(error)
    }

    /**
     * Transforms the success value using the given [transform] function.
     */
    inline fun <R> map(transform: (T) -> R): Result<R, E> = when (this) {
        is Success -> Success(transform(value))
        is Failure -> this
    }

    /**
     * Transforms the error value using the given [transform] function.
     */
    inline fun <R> mapError(transform: (E) -> R): Result<T, R> = when (this) {
        is Success -> this
        is Failure -> Failure(transform(error))
    }

    /**
     * Transforms the success value using the given [transform] function that returns a Result.
     */
    inline fun <R> flatMap(transform: (T) -> Result<R, @UnsafeVariance E>): Result<R, E> = when (this) {
        is Success -> transform(value)
        is Failure -> this
    }

    /**
     * Performs the given [action] if this instance represents [Success].
     * Returns the original Result unchanged.
     */
    inline fun onSuccess(action: (T) -> Unit): Result<T, E> {
        if (this is Success) action(value)
        return this
    }

    /**
     * Performs the given [action] if this instance represents [Failure].
     * Returns the original Result unchanged.
     */
    inline fun onFailure(action: (E) -> Unit): Result<T, E> {
        if (this is Failure) action(error)
        return this
    }

    /**
     * Folds the result into a single value by applying [onSuccess] for success
     * and [onFailure] for failure.
     */
    inline fun <R> fold(onSuccess: (T) -> R, onFailure: (E) -> R): R = when (this) {
        is Success -> onSuccess(value)
        is Failure -> onFailure(error)
    }

    companion object {
        /**
         * Creates a [Success] result with the given [value].
         */
        fun <T> success(value: T): Result<T, Nothing> = Success(value)

        /**
         * Creates a [Failure] result with the given [error].
         */
        fun <E> failure(error: E): Result<Nothing, E> = Failure(error)

        /**
         * Runs the given [block] and wraps the result.
         * Returns [Success] if no exception is thrown, [Failure] with the exception otherwise.
         */
        inline fun <T> runCatching(block: () -> T): Result<T, Throwable> {
            return try {
                Success(block())
            } catch (e: Throwable) {
                Failure(e)
            }
        }
    }
}
