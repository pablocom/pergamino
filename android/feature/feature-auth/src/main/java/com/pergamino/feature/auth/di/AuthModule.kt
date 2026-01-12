package com.pergamino.feature.auth.di

import com.pergamino.feature.auth.data.datasource.AuthLocalDataSource
import com.pergamino.feature.auth.data.datasource.AuthLocalDataSourceImpl
import com.pergamino.feature.auth.data.datasource.AuthRemoteDataSource
import com.pergamino.feature.auth.data.datasource.FakeAuthRemoteDataSource
import com.pergamino.feature.auth.data.repository.AuthRepositoryImpl
import com.pergamino.feature.auth.domain.repository.AuthRepository
import dagger.Binds
import dagger.Module
import dagger.hilt.InstallIn
import dagger.hilt.components.SingletonComponent
import javax.inject.Singleton

/**
 * Hilt module providing authentication dependencies.
 *
 * This module binds interfaces to their implementations, allowing for
 * easy swapping of implementations (e.g., fake vs real remote data source).
 */
@Module
@InstallIn(SingletonComponent::class)
abstract class AuthModule {

    @Binds
    @Singleton
    abstract fun bindAuthRepository(impl: AuthRepositoryImpl): AuthRepository

    @Binds
    @Singleton
    abstract fun bindAuthLocalDataSource(impl: AuthLocalDataSourceImpl): AuthLocalDataSource

    /**
     * Binds the fake remote data source for development.
     *
     * TODO: Replace with real API implementation when backend is ready:
     * @Binds
     * @Singleton
     * abstract fun bindAuthRemoteDataSource(impl: AuthRemoteDataSourceImpl): AuthRemoteDataSource
     */
    @Binds
    @Singleton
    abstract fun bindAuthRemoteDataSource(impl: FakeAuthRemoteDataSource): AuthRemoteDataSource
}
