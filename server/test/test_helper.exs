Mox.defmock(Pergamino.Infrastructure.Auth.AuthorizationCodeStoreMock,
  for: Pergamino.Infrastructure.Auth.AuthorizationCodeStoreBehaviour
)

Mox.defmock(Pergamino.Infrastructure.Auth.RefreshTokenStoreMock,
  for: Pergamino.Infrastructure.Auth.RefreshTokenStoreBehaviour
)

Mox.defmock(Pergamino.Infrastructure.Messaging.EmailSenderMock,
  for: Pergamino.Infrastructure.Messaging.EmailSenderBehaviour
)

Mox.defmock(Pergamino.Core.ClockMock,
  for: Pergamino.Core.Clock
)

ExUnit.start()
