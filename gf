from abc import ABC, abstractmethod
from typing import Dict, Optional, List


class User:
    """
    Пользователь системы бронирования.

    Представляет пользователя, который может бронировать места на мероприятиях.

    Attributes:
        id: Уникальный идентификатор пользователя
        name: Имя пользователя
    """

    def __init__(self, id: str, name: str):
        """
        Инициализация пользователя.

        Args:
            id: Уникальный идентификатор пользователя
            name: Имя пользователя
        """
        self.id = id
        self.name = name


class Seat:
    """
    Место на мероприятии.

    Представляет отдельное место в зале с информацией о его расположении и статусе.

    Attributes:
        id: Уникальный идентификатор места
        row: Номер ряда
        number: Номер места в ряду
        status: Текущий статус места ("free", "reserved", "sold")
        currentUser: Пользователь, связанный с местом (None если место свободно)
    """

    def __init__(self, id: str, row: str, number: str):
        """
        Инициализация места.

        Args:
            id: Уникальный идентификатор места
            row: Номер ряда
            number: Номер места в ряду
        """
        self.id = id
        self.row = row
        self.number = number
        self.status = "free"  # Возможные значения: "free", "reserved", "sold"
        self.currentUser = None


class EventSession:
    """
    Сеанс мероприятия.

    Представляет конкретный сеанс мероприятия с набором мест.

    Attributes:
        id: Уникальный идентификатор сеанса
        time: Время проведения сеанса
        seats: Карта мест, где ключ - идентификатор места, значение - объект Seat
    """

    def __init__(self, id: str, time: str):
        """
        Инициализация сеанса мероприятия.

        Args:
            id: Уникальный идентификатор сеанса
            time: Время проведения сеанса
        """
        self.id = id
        self.time = time
        self.seats: Dict[str, Seat] = {}

    def add_seat(self, seat: Seat):
        """
        Добавить место в сеанс.

        Args:
            seat: Объект Seat для добавления
        """
        self.seats[seat.id] = seat

    def get_seat(self, seatId: str) -> Optional[Seat]:
        """
        Получить место по идентификатору.

        Args:
            seatId: Идентификатор места

        Returns:
            Seat: Объект места если найден, None в противном случае
        """
        return self.seats.get(seatId)


class BookingCommand(ABC):
    """
    Интерфейс команды бронирования.

    Определяет контракт для всех команд системы бронирования.
    Каждая команда должна реализовывать методы execute и undo.
    """

    @abstractmethod
    def execute(self, session: EventSession, seatId: str, user: User) -> bool:
        """
        Выполнить команду бронирования.

        Этот метод должен изменить состояние сеанса и места в соответствии с
        логикой команды.

        Args:
            session: Объект сеанса мероприятия
            seatId: Идентификатор места, над которым выполняется операция
            user: Пользователь, выполняющий операцию

        Returns:
            bool: True если операция выполнена успешно, False в противном случае
        """
        pass

    @abstractmethod
    def undo(self, session: EventSession) -> bool:
        """
        Отменить выполненную команду.

        Этот метод должен восстановить предыдущее состояние сеанса и места.

        Args:
            session: Объект сеанса мероприятия

        Returns:
            bool: True если отмена выполнена успешно, False в противном случае
        """
        pass


class ReserveSeat(BookingCommand):
    """
    Команда бронирования места.

    Переводит место из статуса "free" в статус "reserved" и связывает его с
    пользователем.
    """

    def __init__(self):
        """Инициализация команды с сохранением состояния для отмены."""
        self.original_state = None
        self.seatId = None

    def execute(self, session: EventSession, seatId: str, user: User) -> bool:
        """
        Выполнить бронирование места.

        Проверяет, что место существует и свободно, затем бронирует его для
        пользователя.

        Args:
            session: Объект сеанса мероприятия
            seatId: Идентификатор места для бронирования
            user: Пользователь, для которого выполняется бронирование

        Returns:
            bool: True если место успешно забронировано, False если место занято
                  или не существует
        """
        seat = session.get_seat(seatId)
        if not seat or seat.status != "free":
            return False

        self.original_state = {
            "status": seat.status,
            "currentUser": seat.currentUser
        }
        self.seatId = seatId

        seat.status = "reserved"
        seat.currentUser = user
        return True

    def undo(self, session: EventSession) -> bool:
        """
        Отменить бронирование места.

        Восстанавливает исходное состояние места (свободное).

        Args:
            session: Объект сеанса мероприятия

        Returns:
            bool: True если отмена выполнена успешно, False если нет сохраненного
                  состояния
        """
        if not self.original_state or not self.seatId:
            return False

        seat = session.get_seat(self.seatId)
        if not seat:
            return False

        seat.status = self.original_state["status"]
        seat.currentUser = self.original_state["currentUser"]
        return True


class CancelReservation(BookingCommand):
    """
    Команда отмены бронирования.

    Переводит место из статуса "reserved" обратно в статус "free" и удаляет связь
    с пользователем.
    """

    def __init__(self):
        """Инициализация команды с сохранением состояния для отмены."""
        self.original_state = None
        self.seatId = None

    def execute(self, session: EventSession, seatId: str, user: User) -> bool:
        """
        Выполнить отмену бронирования.

        Проверяет, что место забронировано и принадлежит указанному пользователю,
        затем отменяет бронь.

        Args:
            session: Объект сеанса мероприятия
            seatId: Идентификатор места для отмены бронирования
            user: Пользователь, отменяющий бронирование (должен быть владельцем
                  брони)

        Returns:
            bool: True если бронирование успешно отменено, False если место не
                  забронировано или пользователь не является владельцем
        """
        seat = session.get_seat(seatId)
        if not seat or seat.status != "reserved" or seat.currentUser != user:
            return False

        self.original_state = {
            "status": seat.status,
            "currentUser": seat.currentUser
        }
        self.seatId = seatId

        seat.status = "free"
        seat.currentUser = None
        return True

    def undo(self, session: EventSession) -> bool:
        """
        Отменить отмену бронирования (восстановить бронь).

        Восстанавливает исходное состояние места (забронированное).

        Args:
            session: Объект сеанса мероприятия

        Returns:
            bool: True если восстановление выполнено успешно, False если нет
                  сохраненного состояния
        """
        if not self.original_state or not self.seatId:
            return False

        seat = session.get_seat(self.seatId)
        if not seat:
            return False

        seat.status = self.original_state["status"]
        seat.currentUser = self.original_state["currentUser"]
        return True


class PurchaseTicket(BookingCommand):
    """
    Команда подтверждения брони и оплаты билета.

    Переводит место из статуса "reserved" в статус "sold", подтверждая оплату.
    """

    def __init__(self):
        """Инициализация команды с сохранением состояния для отмены."""
        self.original_state = None
        self.seatId = None

    def execute(self, session: EventSession, seatId: str, user: User) -> bool:
        """
        Выполнить подтверждение брони и оплату.

        Проверяет, что место забронировано и принадлежит указанному пользователю,
        затем подтверждает оплату и переводит место в статус "sold".

        Args:
            session: Объект сеанса мероприятия
            seatId: Идентификатор места для подтверждения оплаты
            user: Пользователь, подтверждающий оплату (должен быть владельцем
                  брони)

        Returns:
            bool: True если оплата успешно подтверждена, False если место не
                  забронировано или пользователь не является владельцем
        """
        seat = session.get_seat(seatId)
        if not seat or seat.status != "reserved" or seat.currentUser != user:
            return False

        self.original_state = {
            "status": seat.status,
            "currentUser": seat.currentUser
        }
        self.seatId = seatId

        seat.status = "sold"
        return True

    def undo(self, session: EventSession) -> bool:
        """
        Отменить подтверждение оплаты (вернуть в статус "reserved").

        Восстанавливает исходное состояние места (забронированное).

        Args:
            session: Объект сеанса мероприятия

        Returns:
            bool: True если отмена выполнена успешно, False если нет сохраненного
                  состояния
        """
        if not self.original_state or not self.seatId:
            return False

        seat = session.get_seat(self.seatId)
        if not seat:
            return False

        seat.status = self.original_state["status"]
        seat.currentUser = self.original_state["currentUser"]
        return True


class ChangeSeat(BookingCommand):
    """
    Команда изменения забронированного места.

    Позволяет пользователю изменить место с одного забронированного на другое
    свободное, сохраняя бронь.
    """

    def __init__(self):
        """Инициализация команды с сохранением состояний для отмены."""
        self.original_from = None
        self.original_to = None
        self.fromId = None
        self.toId = None

    def execute(self, session: EventSession, seatId: str, user: User) -> bool:
        """
        Выполнить изменение места.

        Находит текущее забронированное место пользователя и заменяет его на
        указанное новое место.

        Args:
            session: Объект сеанса мероприятия
            seatId: Идентификатор НОВОГО места (ранее свободного)
            user: Пользователь, изменяющий место (должен иметь существующую
                  бронь)

        Returns:
            bool: True если изменение места выполнено успешно, False если у
                  пользователя нет брони или новое место занято
        """
        current_seat = None
        for s in session.seats.values():
            if s.status == "reserved" and s.currentUser == user:
                current_seat = s
                break

        if not current_seat:
            return False

        new_seat = session.get_seat(seatId)
        if not new_seat or new_seat.status != "free":
            return False

        self.original_from = {
            "status": current_seat.status,
            "currentUser": current_seat.currentUser
        }
        self.original_to = {
            "status": new_seat.status,
            "currentUser": new_seat.currentUser
        }
        self.fromId = current_seat.id
        self.toId = new_seat.id

        current_seat.status = "free"
        current_seat.currentUser = None
        new_seat.status = "reserved"
        new_seat.currentUser = user
        return True

    def undo(self, session: EventSession) -> bool:
        """
        Отменить изменение места (вернуть на исходное место).

        Восстанавливает исходные состояния обоих мест.

        Args:
            session: Объект сеанса мероприятия

        Returns:
            bool: True если отмена выполнена успешно, False если нет сохраненных
                  состояний
        """
        if not all([
            self.original_from,
            self.original_to,
            self.fromId,
            self.toId
        ]):
            return False

        from_seat = session.get_seat(self.fromId)
        to_seat = session.get_seat(self.toId)
        if not from_seat or not to_seat:
            return False

        from_seat.status = self.original_from["status"]
        from_seat.currentUser = self.original_from["currentUser"]
        to_seat.status = self.original_to["status"]
        to_seat.currentUser = self.original_to["currentUser"]
        return True


class BookingProcessor:
    """
    Процессор бронирования.

    Обеспечивает последовательность и атомарность операций бронирования.
    Хранит историю выполненных команд для возможности отмены.
    """

    def __init__(self):
        """
        Инициализация процессора бронирования.

        Создает пустой стек для хранения истории команд.
        """
        self.history: List[BookingCommand] = []

    def execute_command(
        self,
        command: BookingCommand,
        session: EventSession,
        seatId: str,
        user: User
    ) -> bool:
        """
        Выполнить команду бронирования.

        Выполняет команду и сохраняет ее в истории для последующей отмены.
        Обеспечивает атомарность операции - команда либо полностью выполняется,
        либо не выполняется вовсе.

        Args:
            command: Команда для выполнения (ReserveSeat, CancelReservation,
                     PurchaseTicket, ChangeSeat)
            session: Объект сеанса мероприятия
            seatId: Идентификатор места для операции
            user: Пользователь, выполняющий операцию

        Returns:
            bool: True если команда выполнена успешно и сохранена в истории,
                  False если команда не выполнена
        """
        success = command.execute(session, seatId, user)
        if success:
            self.history.append(command)
        return success

    def undo_last_command(self, session: EventSession) -> bool:
        """
        Отменить последнюю выполненную команду.

        Извлекает последнюю команду из истории и выполняет ее отмену.
        Восстанавливает состояние системы до выполнения этой команды.

        Args:
            session: Объект сеанса мероприятия

        Returns:
            bool: True если отмена выполнена успешно, False если история пуста
        """
        if not self.history:
            return False
        return self.history.pop().undo(session)


# Пример использования системы
if __name__ == "__main__":
    # Создаем сеанс мероприятия
    session = EventSession(id="concert_1", time="2026-01-17 20:00")

    # Добавляем места
    session.add_seat(Seat(id="A1", row="A", number="1"))
    session.add_seat(Seat(id="A2", row="A", number="2"))
    session.add_seat(Seat(id="B1", row="B", number="1"))

    # Создаем пользователей
    user1 = User(id="user1", name="Иван Иванов")
    user2 = User(id="user2", name="Мария Петрова")

    # Создаем процессор бронирования
    processor = BookingProcessor()

    print("Начальное состояние мест:")
    for seat_id, seat in session.seats.items():
        print(
            f"Место {seat_id}: статус={seat.status}, "
            f"пользователь={seat.currentUser.name if seat.currentUser else None}"
        )

    print("\n1. Бронирование места A1 для пользователя user1")
    reserve_cmd = ReserveSeat()
    success = processor.execute_command(reserve_cmd, session, "A1", user1)
    print(f"Результат бронирования: {'успешно' if success else 'неудача'}")

    print("\n2. Попытка бронирования того же места A1 для другого пользователя")
    reserve_cmd2 = ReserveSeat()
    success = processor.execute_command(reserve_cmd2, session, "A1", user2)
    print(f"Результат бронирования: {'успешно' if success else 'неудача'}")

    print("\n3. Отмена бронирования места A1")
    cancel_cmd = CancelReservation()
    success = processor.execute_command(cancel_cmd, session, "A1", user1)
    print(f"Результат отмены: {'успешно' if success else 'неудача'}")

    print("\n4. Повторное бронирование места A1 и подтверждение оплаты")
    reserve_cmd3 = ReserveSeat()
    processor.execute_command(reserve_cmd3, session, "A1", user1)

    purchase_cmd = PurchaseTicket()
    success = processor.execute_command(purchase_cmd, session, "A1", user1)
    print(f"Результат оплаты: {'успешно' if success else 'неудача'}")

    print(
        "\n5. Изменение места с A1 на B1 "
        "(должно завершиться неудачей - место A1 уже продано)"
    )
    change_cmd = ChangeSeat()
    success = processor.execute_command(change_cmd, session, "B1", user1)
    print(f"Результат изменения места: {'успешно' if success else 'неудача'}")

    print("\n6. Бронирование места A2 и изменение на B1")
    reserve_cmd4 = ReserveSeat()
    processor.execute_command(reserve_cmd4, session, "A2", user1)

    change_cmd2 = ChangeSeat()
    success = processor.execute_command(change_cmd2, session, "B1", user1)
    print(f"Результат изменения места: {'успешно' if success else 'неудача'}")

    print("\n7. Отмена последней операции (изменения места)")
    success = processor.undo_last_command(session)
    print(f"Результат отмены: {'успешно' if success else 'неудача'}")

    print("\nФинальное состояние мест:")
    for seat_id, seat in session.seats.items():
        print(
            f"Место {seat_id}: статус={seat.status}, "
            f"пользователь={seat.currentUser.name if seat.currentUser else None}"
        )